import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/secure_storage_service.dart';
import 'models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dio, this._secureStorageService);

  final Dio _dio;
  final SecureStorageService _secureStorageService;

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty login response');
    }

    final accessToken = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception('Token payload is missing');
    }

    await _secureStorageService.saveAccessToken(accessToken);
    await _secureStorageService.saveRefreshToken(refreshToken);

    final userId = _extractUserIdFromJwt(accessToken) ?? '';
    return UserModel(id: userId, email: email);
  }

  Future<UserModel> register(String email, String password) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {'email': email, 'password': password},
    );

    // Backend currently issues tokens on login.
    return login(email, password);
  }

  Future<void> logout() {
    return _secureStorageService.clearTokens();
  }

  Future<UserModel> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiConstants.userMe);
    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> body) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiConstants.userMe,
      data: body,
    );
    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid profile update response');
    }
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.userChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  String? _extractUserIdFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    final normalized = base64Url.normalize(parts[1]);
    final payloadMap =
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>;
    return payloadMap['userId']?.toString();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(secureStorageServiceProvider),
  );
});
