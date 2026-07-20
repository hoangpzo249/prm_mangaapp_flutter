import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/story.dart';

class StoryRepository {
  StoryRepository._() : _api = ApiProvider.client;
  static final StoryRepository instance = StoryRepository._();

  StoryRepository.forTesting(this._api);

  final ApiClient _api;

  Future<List<Story>> _stories(String path) async {
    try {
      final res = await _api.get(path);
      return ApiClient.decodeList(res)
          .whereType<Map<String, dynamic>>()
          .map(Story.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Story>> fetchStories() => _stories('/stories');
  Future<List<Story>> fetchRandomStories() => _stories('/stories/random');
  Future<List<Story>> fetchRecentUpdates() => _stories('/stories/recent');
  Future<List<Story>> fetchHotStories() => _stories('/stories/hot');

  Future<List<Story>> searchStories(String keyword) =>
      _stories('/stories/search?keyword=${Uri.encodeComponent(keyword)}');

  Future<Story?> fetchStoryById(String id) async {
    try {
      final res = await _api.get('/stories/$id');
      final data = ApiClient.decodeMap(res);
      return Story.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
