import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/rating_summary.dart';

class RatingRepository {
  RatingRepository._();
  static final RatingRepository instance = RatingRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<RatingSummary> getByStory(String storyId) async {
    final res = await _api.get('/ratings/story/$storyId');
    return RatingSummary.fromJson(ApiClient.decodeMap(res));
  }

  Future<RatingSummary> rateStory(String storyId, int score) async {
    final res = await _api.post(
      '/ratings',
      body: {'storyId': storyId, 'score': score},
      auth: true,
    );
    return RatingSummary.fromJson(ApiClient.decodeMap(res));
  }
}
