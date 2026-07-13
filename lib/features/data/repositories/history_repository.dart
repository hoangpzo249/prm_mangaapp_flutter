import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../application/services/storage_service.dart';
import '../../domain/entities/history_item.dart';

class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  final ApiClient _api = ApiProvider.client;
  final StorageService _storage = StorageService.instance;

  Future<void> syncReadingHistory(String storyId, String chapterId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return;
      await _api.post('/history',
          body: {'storyId': storyId, 'chapterId': chapterId}, auth: true);
    } catch (_) {}
  }

  Future<List<HistoryItem>> getReadingHistory() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return [];
      final res = await _api.get('/history', auth: true);
      return ApiClient.decodeList(res)
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromServer)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Lấy history của user cho 1 truyện (Continue Reading).
  /// Ưu tiên server khi đã login; fallback local cho guest hoặc khi lỗi.
  Future<HistoryItem?> getStoryHistory(String storyId) async {
    final token = await _storage.getToken();
    if (token != null) {
      try {
        final res = await _api.get('/history/story/$storyId', auth: true);
        if (res.statusCode == 200) {
          final body = res.body.trim();
          if (body.isEmpty || body == 'null') {
            return _localForStory(storyId);
          }
          final map = ApiClient.decodeMap(res);
          return HistoryItem.fromServer(map);
        }
      } catch (_) {
        // fall through to local
      }
    }
    return _localForStory(storyId);
  }

  Future<HistoryItem?> _localForStory(String storyId) async {
    final local = await _storage.getLocalHistory();
    for (final h in local) {
      if (h.storyId == storyId && h.chapterId != null) return h;
    }
    return null;
  }

  Future<void> deleteReadingHistory(String storyId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return;
      await _api.delete('/history/$storyId', auth: true);
    } catch (_) {}
  }
}
