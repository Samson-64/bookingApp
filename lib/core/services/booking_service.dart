import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/availability_model.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/person_model.dart';

/// Booking primitives used across the app. All providers share a fixed
/// working-hours window (09:00–17:00) as decided for the current build.
class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  static const String workStart = '09:00';
  static const String workEnd = '17:00';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Booking>> fetchMyBookings() async {
    final response = await _client
        .from('bookings')
        .select('*, people(*), parking_spaces(*), users(name,email)')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('date', ascending: false)
        .order('start_time', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Booking.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Booking>> fetchSpecialistBookings(String personId) async {
    final response = await _client
        .from('bookings')
        .select('*, people(*), parking_spaces(*), users(name,email)')
        .eq('person_id', personId)
        .order('date', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Booking.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Person>> fetchProviders() async {
    final response = await _client.from('people').select();
    return (response as List<dynamic>)
        .map((e) => Person.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Availability> fetchAppointmentAvailability({
    required String personId,
    required String date,
  }) async {
    final response = await _client
        .from('bookings')
        .select('start_time,end_time')
        .eq('person_id', personId)
        .eq('date', date)
        .inFilter('status', ['PENDING', 'CONFIRMED']);

    return Availability(
      working: true,
      scheduleStart: workStart,
      scheduleEnd: workEnd,
      existing: (response as List<dynamic>)
          .map((e) => TimeWindow(
                startTime: _norm(e['start_time']),
                endTime: _norm(e['end_time']),
              ))
          .toList(),
    );
  }

  Future<Booking> createAppointment({
    required String userId,
    required String personId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final reference = _generateReference('APPT');

    final response = await _client
        .from('bookings')
        .insert({
          'user_id': userId,
          'type': 'APPOINTMENT',
          'person_id': personId,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
          'status': 'PENDING',
          'reference': reference,
        })
        .select('*, people(*), parking_spaces(*)')
        .single();

    return Booking.fromMap(Map<String, dynamic>.from(response));
  }

  Future<Booking> createParkingBooking({
    required String userId,
    required String spaceId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final reference = _generateReference('PK');

    final response = await _client
        .from('bookings')
        .insert({
          'user_id': userId,
          'type': 'PARKING',
          'parking_space_id': spaceId,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
          'status': 'PENDING',
          'reference': reference,
        })
        .select('*, people(*), parking_spaces(*)')
        .single();

    return Booking.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    await _client.from('bookings').update({'status': status}).eq('id', bookingId);
  }

  static String _generateReference(String prefix) {
    final rand = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$prefix-$code';
  }

  static String _norm(dynamic v) {
    final s = v?.toString() ?? '00:00';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}