import 'dart:convert';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/chapter.dart';

class ChapterRepository {
  ChapterRepository._();
  static final ChapterRepository instance = ChapterRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<List<Chapter>> fetchChaptersByStoryId(String storyId) async {
    try {
      final res = await _api.get('/chapters/story/$storyId');
      return ApiClient.decodeList(res)
          .whereType<Map<String, dynamic>>()
          .map(Chapter.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Chapter> fetchChapterContent(String chapterId) async {
    final res = await _api.get('/chapters/$chapterId', auth: true);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw VipRequiredException(
        (data['message'] ?? 'Failed to fetch chapter content').toString(),
        requiresVip: data['requiresVip'] == true,
        status: res.statusCode,
      );
    }
    return Chapter.fromJson(data);
  }
}
