import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/auth/data/data_sources/local/login_local_data_source.dart';
import 'package:tribe_up/features/auth/data/models/login_response/user_summary_model.dart';

@Injectable(as: LoginLocalDataSource)
class LoginLocalDataSourceImpl implements LoginLocalDataSource {
  final Box<String> _box;
  final SecureStorageService _secureStorageService;

  LoginLocalDataSourceImpl(this._box, this._secureStorageService);

  @override
  Future<BaseResponse<void>> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _secureStorageService.saveToken(token);
    await _secureStorageService.saveRefreshToken(refreshToken);
    return SuccessResponse<void>(data: null);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorageService.getToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorageService.getRefreshToken();
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorageService.clearAuthData();
  }

  @override
  Future<BaseResponse<void>> saveUserSummary({
    required UserSummaryModel userSummary,
  }) async {
    await _box.put(
      CacheConstants.userSummaryKey,
      jsonEncode(userSummary.toJson()),
    );
    return SuccessResponse<void>(data: null);
  }

  @override
  Future<UserSummaryModel?> getUserSummary() async {
    final userSummary = _box.get(CacheConstants.userSummaryKey);
    if (userSummary != null) {
      return UserSummaryModel.fromJson(jsonDecode(userSummary));
    }
    return null;
  }

  @override
  Future<void> clearUserSummary() async {
    await _box.delete(CacheConstants.userSummaryKey);
  }
}
