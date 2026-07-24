import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';

@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
import 'secure_storage_service_test.mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(mockStorage);
  });

  group('SecureStorageService Test', () {
    const tToken = 'sample_access_token';

    test('should save access token to secure storage', () async {
      when(
        mockStorage.write(key: CacheConstants.tokenKey, value: tToken),
      ).thenAnswer((_) async {});

      await service.saveToken(tToken);

      verify(
        mockStorage.write(key: CacheConstants.tokenKey, value: tToken),
      ).called(1);
    });

    test('should retrieve access token from secure storage', () async {
      when(
        mockStorage.read(key: CacheConstants.tokenKey),
      ).thenAnswer((_) async => tToken);

      final result = await service.getToken();

      expect(result, equals(tToken));
      verify(mockStorage.read(key: CacheConstants.tokenKey)).called(1);
    });

    test('should clear auth data from secure storage', () async {
      when(
        mockStorage.delete(key: CacheConstants.tokenKey),
      ).thenAnswer((_) async {});
      when(
        mockStorage.delete(key: CacheConstants.refreshTokenKey),
      ).thenAnswer((_) async {});

      await service.clearAuthData();

      verify(mockStorage.delete(key: CacheConstants.tokenKey)).called(1);
      verify(mockStorage.delete(key: CacheConstants.refreshTokenKey)).called(1);
    });
  });
}
