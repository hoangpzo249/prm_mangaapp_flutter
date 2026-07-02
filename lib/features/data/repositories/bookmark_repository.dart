import 'dart:convert';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../application/services/storage_service.dart';

class BookmarkRepository {
  BookmarkRepository._();
  static final BookmarkRepository instance = BookmarkRepository._();

  final ApiClient _api = ApiProvider.client;
  final StorageService _storage = StorageService.instance;

  /// Returns `{ isBookmarked, message }`. Throws [NotLoggedInException]
  /// if the user has no auth token.
  Future<Map<String, dynamic>> toggleBookmark(String storyId) async {
    final token = await _storage.getToken();
    if (token == null) throw NotLoggedInException();
    final res =
        await _api.post('/bookmarks/toggle', body: {'storyId': storyId}, auth: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to toggle bookmark', status: res.statusCode);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> checkBookmark(String storyId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;
      final res = await _api.get('/bookmarks/check/$storyId', auth: true);
      if (res.statusCode != 200) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['isBookmarked'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return [];
      final res = await _api.get('/bookmarks', auth: true);
      if (res.statusCode != 200) return [];
      return (jsonDecode(res.body) as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
