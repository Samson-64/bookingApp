import 'person_model.dart';
import 'parking_space_model.dart';

enum BookingType { appointment, parking }
enum BookingStatus { pending, confirmed, completed, cancelled }
enum BookingCategory { upcoming, past }

BookingType bookingTypeFromString(String value) => switch (value) {
      'PARKING' => BookingType.parking,
      _ => BookingType.appointment,
    };

BookingStatus bookingStatusFromString(String value) => switch (value) {
      'CONFIRMED' => BookingStatus.confirmed,
      'COMPLETED' => BookingStatus.completed,
      'CANCELLED' => BookingStatus.cancelled,
      _ => BookingStatus.pending,
    };

String bookingTypeToString(BookingType type) =>
    type == BookingType.parking ? 'PARKING' : 'APPOINTMENT';

class Booking {
  final String id;
  final String userId;
  final BookingType type;
  final BookingStatus status;
  final BookingCategory category;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reference;
  final Person? person;
  final ParkingSpace? space;
  final String? clientName;
  final String? clientEmail;

  Booking({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reference,
    this.person,
    this.space,
    this.clientName,
    this.clientEmail,
  }) : category = date.isBefore(_todayOnly()) ? BookingCategory.past : BookingCategory.upcoming;

  static DateTime _todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isUpcoming => category == BookingCategory.upcoming;
  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  /// Human-readable label for the booked resource (provider or parking space).
  String get title =>
      type == BookingType.appointment ? person?.name ?? 'Appointment' : (space?.name ?? 'Parking');

  String get subtitle => type == BookingType.appointment
      ? person?.position ?? ''
      : (space?.location.isNotEmpty == true ? space!.location : 'Parking Facility');

  factory Booking.fromMap(Map<String, dynamic> map) {
    final rawPerson = map['person'] ?? map['people'];
    final rawSpace = map['parking_space'] ?? map['parking_spaces'];
    final rawClient = map['user'] ?? map['users'];
    final rawUserId = rawClient is Map<String, dynamic> ? rawClient['id'] : map['user_id'];

    return Booking(
      id: map['id'].toString(),
      userId: rawUserId?.toString() ?? '',
      type: bookingTypeFromString(map['type'].toString()),
      status: bookingStatusFromString(map['status']?.toString() ?? ''),
      date: DateTime.parse(map['date']),
      startTime: _normalizeTime(map['startTime'] ?? map['start_time']),
      endTime: _normalizeTime(map['endTime'] ?? map['end_time']),
      reference: map['reference']?.toString() ?? '',
      person: rawPerson is Map<String, dynamic> ? Person.fromMap(rawPerson) : null,
      space: rawSpace is Map<String, dynamic> ? ParkingSpace.fromMap(rawSpace) : null,
      clientName: rawClient is Map<String, dynamic> ? rawClient['name']?.toString() : null,
      clientEmail: rawClient is Map<String, dynamic> ? rawClient['email']?.toString() : null,
    );
  }

  static String _normalizeTime(dynamic value) {
    final s = value?.toString() ?? '00:00';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}