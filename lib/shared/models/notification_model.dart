/// Parses a count that may arrive as an int, a double, or a string.
int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

enum NotificationCategory {
  bookingStatus,
  newBooking,
  reminder,
  system;

  static NotificationCategory fromString(String? value) => switch (value) {
        'BOOKING_STATUS' => NotificationCategory.bookingStatus,
        'NEW_BOOKING' => NotificationCategory.newBooking,
        'REMINDER' => NotificationCategory.reminder,
        _ => NotificationCategory.system,
      };
}

class AppNotification {
  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final String? bookingId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'].toString(),
      category:
          NotificationCategory.fromString(map['category']?.toString()),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      bookingId: map['bookingId']?.toString(),
      read: map['read'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// The feed plus its unread total, as returned by `GET /api/notifications`.
class NotificationFeed {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationFeed({required this.items, required this.unreadCount});

  factory NotificationFeed.fromMap(Map<String, dynamic> map) {
    final raw = map['items'];
    return NotificationFeed(
      items: (raw is List ? raw : const [])
          .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unreadCount: _asInt(map['unreadCount']),
    );
  }
}
