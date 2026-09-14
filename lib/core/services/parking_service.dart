import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/availability_model.dart';
import '../../shared/models/parking_space_model.dart';

class ParkingService {
  ParkingService._();
  static final ParkingService instance = ParkingService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ParkingSpace>> fetchSpaces() async {
    final response = await _client.from('parking_spaces').select().order('location');
    return (response as List<dynamic>)
        .map((e) => ParkingSpace.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Availability of a single space for a specific date based on overlapping
  /// bookings (spaces have no `is_available` column — it is derived).
  Future<Availability> fetchAvailability({
    required String spaceId,
    required String date,
  }) async {
    final response = await _client
        .from('bookings')
        .select('start_time,end_time')
        .eq('parking_space_id', spaceId)
        .eq('date', date)
        .inFilter('status', ['PENDING', 'CONFIRMED']);

    return Availability(
      working: true,
      scheduleStart: BookingServiceRef.workStart,
      scheduleEnd: BookingServiceRef.workEnd,
      existing: (response as List<dynamic>)
          .map((e) => TimeWindow(
                startTime: _norm(e['start_time']),
                endTime: _norm(e['end_time']),
              ))
          .toList(),
    );
  }

  static String _norm(dynamic v) {
    final s = v?.toString() ?? '00:00';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}

/// Small bridge so ParkingService can share the fixed working hours without
/// importing the booking service directly.
class BookingServiceRef {
  static const String workStart = '09:00';
  static const String workEnd = '17:00';
}