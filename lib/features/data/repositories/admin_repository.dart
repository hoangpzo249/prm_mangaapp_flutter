import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/app_user.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final ApiClient _api = ApiProvider.client;

  // --- Statistics ---
  Future<Map<String, dynamic>> fetchOverview() async {
    final res = await _api.get('/stats/overview', auth: true);
    return ApiClient.decodeMap(res);
  }

  Future<List<Map<String, dynamic>>> fetchRevenueChart() async {
    final res = await _api.get('/stats/revenue-chart', auth: true);
    final data = ApiClient.decodeList(res);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchUserGrowthChart() async {
    final res = await _api.get('/stats/user-growth', auth: true);
    final data = ApiClient.decodeList(res);
    return data.cast<Map<String, dynamic>>();
  }

  // --- User Management ---
  Future<List<AppUser>> fetchUsers() async {
    final res = await _api.get('/users', auth: true);
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList();
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final res = await _api.post('/users', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Create user failed',
      );
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/users/$id', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Update user failed',
      );
    }
  }

  Future<void> resetPassword(String id, String newPassword) async {
    final res = await _api.put(
      '/users/$id/reset-password',
      body: {'newPassword': newPassword},
      auth: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Reset password failed',
      );
    }
  }

  Future<void> deleteUser(String id) async {
    final res = await _api.delete('/users/$id', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Delete user failed',
      );
    }
  }

  // --- Reports & Moderation ---
  Future<List<Map<String, dynamic>>> fetchReports() async {
    final res = await _api.get('/reports', auth: true);
    final data = ApiClient.decodeList(res);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> resolveReport(String id, String action) async {
    final res = await _api.put(
      '/reports/$id/resolve',
      body: {'action': action},
      auth: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Resolve report failed',
      );
    }
  }

  Future<void> createReport(
    String targetType,
    String targetId,
    String reason,
  ) async {
    final res = await _api.post(
      '/reports',
      body: {'targetType': targetType, 'targetId': targetId, 'reason': reason},
      auth: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Submit report failed',
      );
    }
  }
}