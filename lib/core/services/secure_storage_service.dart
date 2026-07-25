import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:tribe_up/core/constants/api_constants.dart';

@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: CacheConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: CacheConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: CacheConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(
      key: CacheConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: CacheConstants.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: CacheConstants.refreshTokenKey);
  }

  Future<void> clearAuthData() async {
    await deleteToken();
    await deleteRefreshToken();
  }
}
