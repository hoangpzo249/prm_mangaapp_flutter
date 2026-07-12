import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/story.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<List<AppUser>> getUsers() async {
    final res = await _api.get('/users', auth: true);
    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList();
  }

  Future<AppUser> createUser({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String role = 'user',
    bool isBanned = false,
  }) async {
    final res = await _api.post('/users', auth: true, body: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'fullName': fullName?.trim(),
      'role': role,
      'isBanned': isBanned,
    });
    final data = ApiClient.decodeMap(res);
    return AppUser.fromJson((data['user'] ?? data) as Map<String, dynamic>);
  }

  Future<AppUser> updateUser(
    String id, {
    String? fullName,
    String? role,
    bool? isBanned,
    DateTime? vipUntil,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName.trim();
    if (role != null) body['role'] = role;
    if (isBanned != null) body['isBanned'] = isBanned;
    if (vipUntil != null) body['vipUntil'] = vipUntil.toIso8601String();
    final res = await _api.put('/users/$id', auth: true, body: body);
    return AppUser.fromJson(ApiClient.decodeMap(res));
  }

  Future<void> deleteUser(String id) async {
    final res = await _api.delete('/users/$id', auth: true);
    ApiClient.decodeMap(res);
  }

  Future<List<Story>> getStories() async {
    final res = await _api.get('/stories');
    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList();
  }

  Future<Story> getStory(String id) async {
    final res = await _api.get('/stories/$id');
    return Story.fromJson(ApiClient.decodeMap(res));
  }

  Future<Story> createStory(Map<String, dynamic> body) async {
    final res = await _api.post('/stories', auth: true, body: body);
    return Story.fromJson(ApiClient.decodeMap(res));
  }

  Future<Story> updateStory(String id, Map<String, dynamic> body) async {
    final res = await _api.put('/stories/$id', auth: true, body: body);
    return Story.fromJson(ApiClient.decodeMap(res));
  }

  Future<void> deleteStory(String id) async {
    final res = await _api.delete('/stories/$id', auth: true);
    ApiClient.decodeMap(res);
  }

  Future<List<Chapter>> getChapters(String storyId) async {
    final res = await _api.get('/chapters/story/$storyId');
    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(Chapter.fromJson)
        .toList();
  }

  Future<Chapter> createChapter(Map<String, dynamic> body) async {
    final res = await _api.post('/chapters', auth: true, body: body);
    return Chapter.fromJson(ApiClient.decodeMap(res));
  }

  Future<Chapter> updateChapter(String id, Map<String, dynamic> body) async {
    final res = await _api.put('/chapters/$id', auth: true, body: body);
    return Chapter.fromJson(ApiClient.decodeMap(res));
  }

  Future<void> deleteChapter(String id) async {
    final res = await _api.delete('/chapters/$id', auth: true);
    ApiClient.decodeMap(res);
  }
}
