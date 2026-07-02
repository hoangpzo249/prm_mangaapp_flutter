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

  Future<void> deleteReadingHistory(String storyId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return;
      await _api.delete('/history/$storyId', auth: true);
    } catch (_) {}
  }
}
