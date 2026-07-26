import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/features/auth/data/models/sign_up_request/sign_up_request_model.dart';
import 'package:tribe_up/features/auth/data/models/sign_up_response/sign_up_response_model.dart';

part 'sign_up_api_client.g.dart';

@singleton
@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class SignUpApiClient {
  @factoryMethod
  factory SignUpApiClient(Dio dio) = _SignUpApiClient;

  @POST(ApiConstants.registerEndPoint)
  Future<SignUpResponseModel> signUp(@Body() SignUpRequestModel signUpRequest);
}
