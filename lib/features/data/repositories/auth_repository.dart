import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../application/services/storage_service.dart';
import '../../domain/entities/app_user.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final ApiClient _api = ApiProvider.client;
  final StorageService _storage = StorageService.instance;

  Future<AppUser> login(String username, String password) async {
    final res = await _api.post('/auth/login', body: {
      'username': username,
      'password': password,
    });
    final data = ApiClient.decodeMap(res);
    if (data['token'] != null) {
      await _storage.setToken(data['token']);
    }
    final user = AppUser.fromJson((data['user'] ?? {}) as Map<String, dynamic>);
    if (data['user'] != null) await _storage.setUserInfo(user);
    return user;
  }

  Future<void> sendRegisterOtp(String email) async {
    final res = await _api.post('/auth/register/send-otp', body: {
      'email': email,
    });
    ApiClient.decodeMap(res);
  }

  Future<void> register(String username, String email, String password, String fullName) async {
    final res = await _api.post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    ApiClient.decodeMap(res); // throws ApiException (with fieldErrors) on non-2xx
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final res = await _api.post('/auth/change-password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }, auth: true);
    ApiClient.decodeMap(res);
  }

  Future<void> forgotPassword(String email) async {
    final res = await _api.post('/auth/forgot-password', body: {
      'email': email,
    });
    ApiClient.decodeMap(res);
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final res = await _api.post('/auth/reset-password', body: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    ApiClient.decodeMap(res);
  }
 
  Future<AppUser> fetchMe() async {
    final res = await _api.get('/users/me', auth: true);
    final data = ApiClient.decodeMap(res);
    final user = AppUser.fromJson(data);
    await _storage.setUserInfo(user);
    return user;
  }

  Future<AppUser> updateProfile(String fullName, {String? avatarUrl}) async {
    final body = <String, dynamic>{'fullName': fullName};
    if (avatarUrl != null) {
      body['avatar'] = avatarUrl;
    }
    final res = await _api.put('/users/me', body: body, auth: true);
    final data = ApiClient.decodeMap(res);
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.setUserInfo(user);
    return user;
  }

  Future<void> logout() => _storage.clearAuth();

  Future<AppUser?> getUserData() => _storage.getUser();
}