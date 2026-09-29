/// The signed-in user's saved preferences.
///
/// There is deliberately no theme field: the app is light-only, so exposing a
/// theme switch would be a setting that does nothing.
class UserSettings {
  final String language;
  final String timezone;
  final int defaultDurationMinutes;
  final String? preferredParkingFloor;

  final bool notifyBookingUpdates;
  final bool notifyNewBookings;
  final bool notifyReminders;
  final int reminderMinutesBefore;

  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const UserSettings({
    required this.language,
    required this.timezone,
    required this.defaultDurationMinutes,
    required this.preferredParkingFloor,
    required this.notifyBookingUpdates,
    required this.notifyNewBookings,
    required this.notifyReminders,
    required this.reminderMinutesBefore,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      language: map['language']?.toString() ?? 'en',
      timezone: map['timezone']?.toString() ?? 'UTC',
      defaultDurationMinutes: _toInt(map['defaultDurationMinutes'], 60),
      preferredParkingFloor: map['preferredParkingFloor']?.toString(),
      notifyBookingUpdates: map['notifyBookingUpdates'] != false,
      notifyNewBookings: map['notifyNewBookings'] != false,
      notifyReminders: map['notifyReminders'] != false,
      reminderMinutesBefore: _toInt(map['reminderMinutesBefore'], 60),
      quietHoursEnabled: map['quietHoursEnabled'] == true,
      quietHoursStart: map['quietHoursStart']?.toString() ?? '22:00',
      quietHoursEnd: map['quietHoursEnd']?.toString() ?? '07:00',
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  UserSettings copyWith({
    String? language,
    String? timezone,
    int? defaultDurationMinutes,
    String? preferredParkingFloor,
    bool clearPreferredParkingFloor = false,
    bool? notifyBookingUpdates,
    bool? notifyNewBookings,
    bool? notifyReminders,
    int? reminderMinutesBefore,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return UserSettings(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
      preferredParkingFloor: clearPreferredParkingFloor
          ? null
          : (preferredParkingFloor ?? this.preferredParkingFloor),
      notifyBookingUpdates: notifyBookingUpdates ?? this.notifyBookingUpdates,
      notifyNewBookings: notifyNewBookings ?? this.notifyNewBookings,
      notifyReminders: notifyReminders ?? this.notifyReminders,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
