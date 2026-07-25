import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/network/auth_interceptor.dart';
import 'package:tribe_up/core/network/device_id_manager.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';

@module
abstract class SecureStorageModule {
  @singleton
  FlutterSecureStorage get storage => const FlutterSecureStorage();
}

@module
abstract class DioModule {
  @lazySingleton
  Dio dio(
    DeviceIdManager deviceIdManager,
    SecureStorageService secureStorageService,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Device-Id': deviceIdManager.deviceId,
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        secureStorageService: secureStorageService,
        deviceIdManager: deviceIdManager,
        baseUrl: ApiConstants.baseUrl,
      ),
    );
    dio.interceptors.add(
      PrettyDioLogger(
        request: true,
        error: true,
        requestBody: true,
        compact: true,
        responseBody: true,
      ),
    );

    return dio;
  }
}

@module
abstract class SharedPrefModule {
  @singleton
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

@module
abstract class HiveModule {
  @preResolve
  @singleton
  Future<HiveInterface> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(CacheConstants.tokenBoxName);
    await Hive.openBox<String>(CacheConstants.deviceIdBoxName);
    await Hive.openBox<String>(CacheConstants.storiesBoxName);
    return Hive;
  }

  @singleton
  Box<String> tokenBox() {
    return Hive.box<String>(CacheConstants.tokenBoxName);
  }

  @singleton
  @Named(CacheConstants.deviceIdBoxName)
  Box<String> deviceIdBox() {
    return Hive.box<String>(CacheConstants.deviceIdBoxName);
  }

  @singleton
  @Named(CacheConstants.storiesBoxName)
  Box<String> storiesBox() {
    return Hive.box<String>(CacheConstants.storiesBoxName);
  }
}
