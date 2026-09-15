import '../../shared/models/availability_model.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/person_model.dart';
import '../network/api_client.dart';

/// Booking primitives used across the app. All providers share a fixed
/// working-hours window (09:00–17:00) as decided for the current build.
class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  static const String workStart = '09:00';
  static const String workEnd = '17:00';

  ApiClient get _api => ApiClient.instance;

  Future<List<Booking>> fetchMyBookings() async {
    final res = await _api.get<List<dynamic>>('/api/bookings');
    return (res.data ?? const [])
        .map((e) => Booking.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Booking>> fetchSpecialistBookings(String personId) async {
    // The backend resolves the specialist from the signed-in user's token,
    // so the personId argument is not sent over the wire.
    final res = await _api.get<List<dynamic>>('/api/specialist/my-appointments');
    return (res.data ?? const [])
        .map((e) => Booking.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Person>> fetchProviders() async {
    final res = await _api.get<List<dynamic>>('/api/people');
    return (res.data ?? const [])
        .map((e) => Person.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Availability> fetchAppointmentAvailability({
    required String personId,
    required String date,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/appointments/availability',
      queryParameters: {'person_id': personId, 'date': date},
    );
    return Availability.fromMap(
      Map<String, dynamic>.from(res.data ?? const {}),
    );
  }

  Future<Booking> createAppointment({
    required String userId,
    required String personId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    // The backend attaches the signed-in user from the token.
    final res = await _api.post<Map<String, dynamic>>(
      '/api/appointments',
      data: {
        'personId': personId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return Booking.fromMap(Map<String, dynamic>.from(res.data ?? const {}));
  }

  Future<Booking> createParkingBooking({
    required String userId,
    required String spaceId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    // The backend attaches the signed-in user from the token.
    final res = await _api.post<Map<String, dynamic>>(
      '/api/parking/book',
      data: {
        'parkingSpaceId': spaceId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return Booking.fromMap(Map<String, dynamic>.from(res.data ?? const {}));
  }

  /// Updates a booking status (staff scope: any booking).
  Future<Booking> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/api/bookings/$bookingId/status',
      data: {'status': status},
    );
    return Booking.fromMap(Map<String, dynamic>.from(res.data ?? const {}));
  }

  /// Updates a booking status (specialist scope: own appointments only).
  Future<Booking> updateSpecialistStatus({
    required String bookingId,
    required String status,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/api/specialist/bookings/$bookingId/status',
      data: {'status': status},
    );
    return Booking.fromMap(Map<String, dynamic>.from(res.data ?? const {}));
  }
}