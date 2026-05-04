import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: refreshTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> deleteAccessToken() {
    return _storage.delete(key: accessTokenKey);
  }

  Future<void> deleteRefreshToken() {
    return _storage.delete(key: refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([deleteAccessToken(), deleteRefreshToken()]);
  }
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.read(flutterSecureStorageProvider));
});
