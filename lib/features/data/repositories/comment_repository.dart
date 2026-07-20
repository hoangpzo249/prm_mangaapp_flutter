import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/comment_item.dart';

class CommentRepository {
  final ApiClient _api;

  CommentRepository({ApiClient? api})
      : _api = api ?? ApiProvider.client;

  static final CommentRepository instance = CommentRepository();

  Future<List<CommentItem>> getByStory(
    String storyId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(
      '/comments/story/$storyId?page=$page&limit=$limit',
    );

    return ApiClient.decodeList(res)
        .whereType<Map<String, dynamic>>()
        .map(CommentItem.fromJson)
        .toList();
  }

  Future<CommentItem> create({
    required String storyId,
    required String content,
    String? chapterId,
    String? parentId,
  }) async {
    final body = <String, dynamic>{
      'storyId': storyId,
      'content': content.trim(),
    };

    if (chapterId != null && chapterId.isNotEmpty) {
      body['chapterId'] = chapterId;
    }

    if (parentId != null && parentId.isNotEmpty) {
      body['parentId'] = parentId;
    }

    final res = await _api.post(
      '/comments',
      body: body,
      auth: true,
    );

    return CommentItem.fromJson(
      ApiClient.decodeMap(res),
    );
  }

  Future<void> deleteComment(String commentId) async {
    final res = await _api.delete(
      '/comments/$commentId',
      auth: true,
    );

    ApiClient.decodeMap(res);
  }
}