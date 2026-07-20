import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mangaflutter/core/networks/api_client.dart';
import 'package:mangaflutter/core/errors/app_exceptions.dart';
import 'package:mangaflutter/features/application/services/storage_service.dart';
import 'package:mangaflutter/features/data/repositories/auth_repository.dart';
import 'package:mangaflutter/features/domain/entities/app_user.dart';
 
class MockApiClient extends Mock implements ApiClient {}
class MockStorageService extends Mock implements StorageService {}
class FakeAppUser extends Fake implements AppUser {}
 
void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppUser());
  });
 
  late AuthRepository authRepository;
  late MockApiClient mockApi;
  late MockStorageService mockStorage;
 
  setUp(() {
    mockApi = MockApiClient();
    mockStorage = MockStorageService();
    authRepository = AuthRepository.test(api: mockApi, storage: mockStorage);
  });
 
  group('AuthRepository Tests', () {
    final mockUserMap = {
      '_id': '123',
      'username': 'testuser',
      'email': 'test@example.com',
      'role': 'user',
      'createdAt': '2023-01-01T00:00:00.000Z',
    };
    final mockUser = AppUser.fromJson(mockUserMap);
 
    test('Đăng nhập thành công thì lưu token và thông tin người dùng', () async {
      // Arrange
      final mockResponseMap = {
        'token': 'mock-token',
        'user': mockUserMap,
      };
 
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponseMap), 200));
 
      when(() => mockStorage.setToken(any())).thenAnswer((_) async => true);
      when(() => mockStorage.setUserInfo(any())).thenAnswer((_) async => true);
 
      // Act
      final user = await authRepository.login('testuser', 'password');
 
      // Assert
      expect(user.id, '123');
      expect(user.username, 'testuser');
 
      verify(() => mockApi.post('/auth/login', body: {
        'username': 'testuser',
        'password': 'password',
      })).called(1);
      verify(() => mockStorage.setToken('mock-token')).called(1);
      verify(() => mockStorage.setUserInfo(any())).called(1);
    });
 
    test('Đăng nhập thất bại thì ném ra ApiException', () async {
      // Arrange
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Invalid credentials'}), 401));
 
      // Act & Assert
      expect(
        () => authRepository.login('testuser', 'wrong'),
        throwsA(isA<ApiException>()),
      );
    });
 
    test('Đăng ký thành công không ném ra ngoại lệ', () async {
      // Arrange
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Registered successfully'}), 200));
 
      // Act
      await authRepository.register('newuser', 'new@example.com', 'pass123', 'New User');
 
      // Assert
      verify(() => mockApi.post('/auth/register', body: {
        'username': 'newuser',
        'email': 'new@example.com',
        'password': 'pass123',
        'fullName': 'New User',
      })).called(1);
    });
 
    test('Đăng ký thất bại chung ném ra ApiException', () async {
      // Arrange
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Username already exists'}), 400));
 
      // Act & Assert
      expect(
        () => authRepository.register('newuser', 'new@example.com', 'pass123', 'New User'),
        throwsA(isA<ApiException>()),
      );
    });
 
    test('Đăng ký thất bại do email không hợp lệ trả về fieldErrors', () async {
      // Arrange
      final errorResponse = {
        'message': 'Validation error',
        'errors': [
          {'field': 'email', 'message': 'Email không hợp lệ'}
        ]
      };
 
      // headers charset=utf-8 -> tránh lỗi ArgumentError khi body chứa ký tự có dấu
      // (http.Response tự chọn encoding dựa vào content-type header,
      // mặc định là Latin1 nếu không khai báo charset, không encode được tiếng Việt)
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(errorResponse),
                400,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ));
 
      // Act & Assert
      expect(
        () => authRepository.register('newuser', 'invalid-email', 'pass123', 'New User'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fieldErrors,
            'fieldErrors',
            {'email': 'Email không hợp lệ'},
          ),
        ),
      );
    });
 
    test('Đăng ký thất bại do mật khẩu không đủ điều kiện trả về fieldErrors', () async {
      // Arrange
      final errorResponse = {
        'message': 'Validation error',
        'errors': [
          {'field': 'password', 'message': 'Mật khẩu quá ngắn'}
        ]
      };
 
      // headers charset=utf-8 -> tránh lỗi ArgumentError khi body chứa ký tự có dấu
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(errorResponse),
                400,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ));
 
      // Act & Assert
      expect(
        () => authRepository.register('newuser', 'new@example.com', '12', 'New User'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fieldErrors,
            'fieldErrors',
            {'password': 'Mật khẩu quá ngắn'},
          ),
        ),
      );
    });
 
    test('Lấy thông tin người dùng thành công thì trả về AppUser và lưu lại', () async {
      // Arrange
      when(() => mockApi.get(any(), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockUserMap), 200));
 
      when(() => mockStorage.setUserInfo(any())).thenAnswer((_) async => true);
 
      // Act
      final user = await authRepository.fetchMe();
 
      // Assert
      expect(user.id, '123');
      expect(user.username, 'testuser');
 
      verify(() => mockApi.get('/users/me', auth: true)).called(1);
      verify(() => mockStorage.setUserInfo(any())).called(1);
    });
 
    test('Đổi mật khẩu thành công không ném ra ngoại lệ', () async {
      // Arrange
      when(() => mockApi.post(any(), body: any(named: 'body'), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Success'}), 200));
 
      // Act
      await authRepository.changePassword('old123', 'new123');
 
      // Assert
      verify(() => mockApi.post('/auth/change-password', body: {
        'oldPassword': 'old123',
        'newPassword': 'new123',
      }, auth: true)).called(1);
    });
 
    test('Đổi mật khẩu thất bại ném ra ApiException', () async {
      // Arrange
      when(() => mockApi.post(any(), body: any(named: 'body'), auth: any(named: 'auth')))
          .thenAnswer((_) async => http.Response(jsonEncode({'message': 'Wrong password'}), 400));
 
      // Act & Assert
      expect(
        () => authRepository.changePassword('old123', 'new123'),
        throwsA(isA<ApiException>()),
      );
    });
 
    test('Đăng xuất thì xoá thông tin xác thực', () async {
      // Arrange
      when(() => mockStorage.clearAuth()).thenAnswer((_) async => true);
 
      // Act
      await authRepository.logout();
 
      // Assert
      verify(() => mockStorage.clearAuth()).called(1);
    });
  });
}
 
