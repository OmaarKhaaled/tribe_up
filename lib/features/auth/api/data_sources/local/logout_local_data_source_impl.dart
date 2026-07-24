import 'package:injectable/injectable.dart';
import 'package:tribe_up/config/base_response/base_response.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/auth/data/data_sources/local/logout_local_data_source.dart';

@Injectable(as: LogoutLocalDataSource)
class LogoutLocalDataSourceImpl implements LogoutLocalDataSource {
  final SecureStorageService _secureStorageService;

  LogoutLocalDataSourceImpl(this._secureStorageService);

  @override
  Future<BaseResponse<void>> clearTokens() async {
    await _secureStorageService.clearAuthData();
    return SuccessResponse<void>(data: null);
  }
}
