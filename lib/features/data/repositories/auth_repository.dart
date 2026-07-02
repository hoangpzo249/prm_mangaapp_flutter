import '../../../core/errors/app_exceptions.dart';
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
    final res = await _api.post('/users/login', body: {
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

  Future<void> register(String username, String password) async {
    final res = await _api.post('/users/register', body: {
      'username': username,
      'password': password,
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      ApiClient.decodeMap(res);
    }
  }

  Future<void> logout() => _storage.clearAuth();

  Future<AppUser?> getUserData() => _storage.getUser();

  Future<void> upgradeToVip() async {
    final token = await _storage.getToken();
    if (token == null) throw ApiException('No token found');
    final res = await _api.post('/users/upgrade-vip', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      ApiClient.decodeMap(res);
    }
  }
}
