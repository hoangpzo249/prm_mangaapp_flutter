import '../../../core/networks/api_client.dart';
import '../../application/services/api_provider.dart';
import '../../domain/entities/app_notification.dart';

class NotificationResult {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationResult({required this.notifications, required this.unreadCount});
}

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final ApiClient _api = ApiProvider.client;

  Future<NotificationResult> getNotifications({int page = 1, int limit = 20}) async {
    final res = await _api.get('/notifications?page=$page&limit=$limit', auth: true);
    final data = ApiClient.decodeMap(res);
    final raw = data['notifications'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList()
        : <AppNotification>[];
    return NotificationResult(
      notifications: items,
      unreadCount: data['unreadCount'] is num ? (data['unreadCount'] as num).toInt() : 0,
    );
  }

  Future<AppNotification> markAsRead(String id) async {
    final res = await _api.put('/notifications/$id/read', auth: true);
    return AppNotification.fromJson(ApiClient.decodeMap(res));
  }

  Future<void> markAllAsRead() async {
    final res = await _api.put('/notifications/read-all', auth: true);
    ApiClient.decodeMap(res);
  }
}
