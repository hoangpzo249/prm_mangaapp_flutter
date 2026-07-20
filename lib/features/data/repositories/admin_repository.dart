import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/story.dart';

class AdminRepository {
  AdminRepository._() : _api = ApiProvider.client;
  static final AdminRepository instance = AdminRepository._();

  AdminRepository.forTesting(this._api);

  final ApiClient _api;

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

  // --- Story Management ---
  Future<List<Story>> fetchStories() async {
    final res = await _api.get('/stories');
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList();
  }

  Future<Story> fetchStoryById(String id) async {
    final res = await _api.get('/stories/$id');
    final data = ApiClient.decodeMap(res);
    return Story.fromJson(data);
  }

  Future<void> createStory(Map<String, dynamic> data) async {
    final res = await _api.post('/stories', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Create story failed',
      );
    }
  }

  Future<void> updateStory(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/stories/$id', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Update story failed',
      );
    }
  }

  /// Soft delete: đánh dấu ẩn truyện (backend chỉ set isHidden=true)
  Future<void> deleteStory(String id) async {
    final res = await _api.delete('/stories/$id', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Hide story failed',
      );
    }
  }

  Future<void> restoreStory(String id) async {
    final res = await _api.post('/stories/$id/restore', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Restore story failed',
      );
    }
  }

  Future<List<Story>> fetchHiddenStories() async {
    final res = await _api.get('/stories/admin/hidden', auth: true);
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList();
  }

  // --- Chapter Management ---
  Future<List<Chapter>> fetchChaptersByStory(String storyId) async {
    final res = await _api.get('/chapters/story/$storyId');
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Chapter.fromJson)
        .toList();
  }

  Future<void> createChapter(Map<String, dynamic> data) async {
    final res = await _api.post('/chapters', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Create chapter failed',
      );
    }
  }

  Future<void> updateChapter(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/chapters/$id', body: data, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Update chapter failed',
      );
    }
  }

  /// Soft delete: đánh dấu ẩn chapter (backend chỉ set isHidden=true)
  Future<void> deleteChapter(String id) async {
    final res = await _api.delete('/chapters/$id', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Hide chapter failed',
      );
    }
  }

  Future<void> restoreChapter(String id) async {
    final res = await _api.post('/chapters/$id/restore', auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        ApiClient.decodeMap(res)['message'] ?? 'Restore chapter failed',
      );
    }
  }

  Future<List<Chapter>> fetchHiddenChaptersByStory(String storyId) async {
    final res = await _api.get(
      '/chapters/admin/story/$storyId/hidden',
      auth: true,
    );
    final data = ApiClient.decodeList(res);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Chapter.fromJson)
        .toList();
  }

  // --- Reports & Moderation ---
  Future<Map<String, dynamic>> fetchReports({
    String? status,
    int? page,
    int? limit,
  }) async {
    final query = <String>[];
    if (status != null && status != 'all') query.add('status=$status');
    if (page != null) query.add('page=$page');
    if (limit != null) query.add('limit=$limit');
    
    final queryString = query.isNotEmpty ? '?${query.join('&')}' : '';
    final res = await _api.get('/reports$queryString', auth: true);
    return ApiClient.decodeMap(res);
  }

  Future<void> resolveReport(String id, String action, {String? adminNote}) async {
    final body = <String, dynamic>{'action': action};
    if (adminNote != null && adminNote.isNotEmpty) {
      body['adminNote'] = adminNote;
    }
    final res = await _api.put(
      '/reports/$id/resolve',
      body: body,
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