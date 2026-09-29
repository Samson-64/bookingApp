import '../../shared/models/notification_model.dart';
import '../network/api_client.dart';

/// Thin wrapper over the notification endpoints. State lives in
/// [NotificationController]; this class only talks to the API.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  ApiClient get _api => ApiClient.instance;

  Future<NotificationFeed> fetchFeed() async {
    final res = await _api.get<Map<String, dynamic>>('/api/notifications');
    return NotificationFeed.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  Future<int> fetchUnreadCount() async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/notifications/unread-count',
    );
    // This endpoint returns a bare {count}, unlike the feed's {unreadCount}.
    final data = Map<String, dynamic>.from(res.data ?? {});
    final count = data['count'];
    if (count is num) return count.toInt();
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<void> markRead(String id) async {
    await _api.patch('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.post('/api/notifications/read-all');
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/notifications/$id');
  }
}
