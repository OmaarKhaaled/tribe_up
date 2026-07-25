import 'package:dio/dio.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/network/device_id_manager.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/auth/data/models/login_request/refresh_token_request_model.dart';
import 'package:tribe_up/features/auth/data/models/login_response/login_response_model.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService secureStorageService;
  final DeviceIdManager deviceIdManager;
  final String baseUrl;

  AuthInterceptor({
    required this.secureStorageService,
    required this.deviceIdManager,
    required this.baseUrl,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await secureStorageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Use a fresh Dio instance to avoid circular dependency
          final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
          final response = await refreshDio.post(
            ApiConstants.refreshEndPoint,
            data: RefreshTokenRequestModel(
              refreshToken: refreshToken,
              deviceId: deviceIdManager.deviceId,
            ).toJson(),
          );

          if (response.statusCode == 200) {
            final loginResponse = LoginResponseModel.fromJson(response.data);
            if (loginResponse.accessToken != null &&
                loginResponse.refreshToken != null) {
              await secureStorageService.saveToken(loginResponse.accessToken!);
              await secureStorageService.saveRefreshToken(
                loginResponse.refreshToken!,
              );

              // Retry the original request
              final options = err.requestOptions;
              options.headers['Authorization'] =
                  'Bearer ${loginResponse.accessToken}';

              final retryResponse = await refreshDio.request(
                options.path,
                data: options.data,
                queryParameters: options.queryParameters,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
              );

              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          // If refresh fails, clear tokens
          await secureStorageService.clearAuthData();
        }
      }
    }
    return handler.next(err);
  }
}
