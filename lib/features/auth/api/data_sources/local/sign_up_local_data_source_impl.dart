import 'package:injectable/injectable.dart';
import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/auth/data/data_sources/local/sign_up_local_data_source.dart';

@Injectable(as: SignUpLocalDataSource)
class SignUpLocalDataSourceImpl implements SignUpLocalDataSource {
  final SecureStorageService _secureStorageService;

  SignUpLocalDataSourceImpl(this._secureStorageService);

  @override
  Future<BaseResponse<void>> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await _secureStorageService.saveToken(token);
    await _secureStorageService.saveRefreshToken(refreshToken);
    return SuccessResponse<void>(data: null);
  }
}
