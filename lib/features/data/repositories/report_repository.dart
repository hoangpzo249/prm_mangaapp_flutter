import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';

class ReportRepository {
  ReportRepository({ApiClient? api}) : _api = api ?? ApiProvider.client;

  ReportRepository._() : this();

  static final ReportRepository instance = ReportRepository._();

  final ApiClient _api;

  Future<void> createReport(
    String targetType,
    String targetId,
    String reason,
  ) async {
    final normalizedType = targetType.trim().toLowerCase();
    final normalizedTargetId = targetId.trim();
    final normalizedReason = reason.trim();

    if (normalizedType.isEmpty ||
        normalizedTargetId.isEmpty ||
        normalizedReason.isEmpty) {
      throw Exception('Target type, target ID and reason are required');
    }

    if (normalizedType != 'story' && normalizedType != 'comment') {
      throw Exception('Invalid report target type');
    }

    final res = await _api.post(
      '/reports',
      body: {
        'targetType': normalizedType,
        'targetId': normalizedTargetId,
        'reason': normalizedReason,
      },
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = ApiClient.decodeMap(res);
      throw Exception(data['message']?.toString() ?? 'Submit report failed');
    }
  }

  Future<void> reportStory(String storyId, String reason) async {
    await createReport('story', storyId, reason);
  }

  Future<void> reportComment(String commentId, String reason) async {
    await createReport('comment', commentId, reason);
  }
}
