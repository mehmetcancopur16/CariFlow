import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';

import '../constants/api_constants.dart';
import 'session_state_provider.dart';
import 'secure_storage_service.dart';

class DioClient {
  DioClient(this._secureStorageService, {required this.onSessionInvalidated})
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
  final Future<void> Function() onSessionInvalidated;

  bool _isRefreshing = false;

  void configureCertificatePinning() {
    // NOTE: Replace with your real production certificate SHA-256 fingerprints.
    const pinnedSha256Fingerprints = <String>[
      'SHA256 fingerprint of your server certificate',
    ];

    final adapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              // Development convenience for local non-production endpoints.
              if (host == '10.0.2.2' || host == 'localhost') {
                return true;
              }

              final certSha256 = sha256
                  .convert(utf8.encode(cert.pem))
                  .toString()
                  .toUpperCase();
              return pinnedSha256Fingerprints.any(
                (fp) => fp.trim().toUpperCase() == certSha256,
              );
            };
        return client;
      },
    );

    dio.httpClientAdapter = adapter;
  }

  void _attachInterceptors() {
    configureCertificatePinning();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorageService.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
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
              await onSessionInvalidated();
              handler.next(error);
              return;
            }

            final newAccessToken = await _secureStorageService
                .readAccessToken();
            if (newAccessToken == null || newAccessToken.isEmpty) {
              handler.next(error);
              return;
            }

            options.headers['Authorization'] = 'Bearer $newAccessToken';
            options.extra['retried'] = true;

            final retryResponse = await dio.fetch(options);
            handler.resolve(retryResponse);
          } catch (_) {
            await _secureStorageService.clearTokens();
            await onSessionInvalidated();
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
  return DioClient(
    ref.read(secureStorageServiceProvider),
    onSessionInvalidated: () async {
      ref.read(sessionVersionProvider.notifier).bump();
    },
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.read(dioClientProvider).dio;
});
