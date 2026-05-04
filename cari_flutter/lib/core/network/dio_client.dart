import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'secure_storage_service.dart';

class DioClient {
  DioClient(this._secureStorageService)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _attachInterceptors();
  }

  final SecureStorageService _secureStorageService;
  final Dio dio;

  bool _isRefreshing = false;

  void _attachInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorageService.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final options = error.requestOptions;

          final isUnauthorized = response?.statusCode == 401;
          final isRefreshEndpoint = options.path.endsWith(ApiConstants.refresh);
          final hasRetried = options.extra['retried'] == true;

          if (!isUnauthorized || isRefreshEndpoint || hasRetried) {
            handler.next(error);
            return;
          }

          if (_isRefreshing) {
            handler.next(error);
            return;
          }

          _isRefreshing = true;

          try {
            final refreshed = await _refreshAccessToken();

            if (!refreshed) {
              await _secureStorageService.clearTokens();
              handler.next(error);
              return;
            }

            final newAccessToken = await _secureStorageService
                .readAccessToken();
            if (newAccessToken == null || newAccessToken.isEmpty) {
              handler.next(error);
              return;
            }

            options.headers['Authorization'] = 'Bearer ';
            options.extra['retried'] = true;

            final retryResponse = await dio.fetch(options);
            handler.resolve(retryResponse);
          } catch (_) {
            await _secureStorageService.clearTokens();
            handler.next(error);
          } finally {
            _isRefreshing = false;
          }
        },
      ),
    );
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _secureStorageService.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await dio.post<dynamic>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final accessToken = data['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      return false;
    }

    await _secureStorageService.saveAccessToken(accessToken);
    return true;
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.read(secureStorageServiceProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return ref.read(dioClientProvider).dio;
});
