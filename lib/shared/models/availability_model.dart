class TimeWindow {
  final String startTime;
  final String endTime;

  const TimeWindow({required this.startTime, required this.endTime});
}

class Availability {
  final bool working;
  final String scheduleStart;
  final String scheduleEnd;
  final List<TimeWindow> existing;

  const Availability({
    required this.working,
    this.scheduleStart = '09:00',
    this.scheduleEnd = '17:00',
    this.existing = const [],
  });

  bool get hasSchedule => working;

  bool intersects(String start, String end) {
    return existing.any((w) => _overlaps(start, end, w.startTime, w.endTime));
  }

  factory Availability.fromMap(Map<String, dynamic> map) {
    final schedule = map['schedule'];
    final Map<String, dynamic> scheduleMap =
        schedule is Map<String, dynamic> ? schedule : const {};
    final existingRaw = (map['existing'] ?? map['bookings'] ?? const []) as List<dynamic>;

    return Availability(
      working: map['working'] == true,
      scheduleStart:
          _norm(scheduleMap['startTime'] ?? scheduleMap['start_time'] ?? map['schedule_start']) ??
              '09:00',
      scheduleEnd:
          _norm(scheduleMap['endTime'] ?? scheduleMap['end_time'] ?? map['schedule_end']) ??
              '17:00',
      existing: existingRaw
          .map((e) => e is Map
              ? TimeWindow(
                  startTime: _norm(e['startTime'] ?? e['start_time']) ?? '00:00',
                  endTime: _norm(e['endTime'] ?? e['end_time']) ?? '00:00',
                )
              : const TimeWindow(startTime: '00:00', endTime: '00:00'))
          .toList(),
    );
  }

  static String? _norm(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  static bool _overlaps(String aStart, String aEnd, String bStart, String bEnd) {
    return _toMinutes(aStart) < _toMinutes(bEnd) &&
        _toMinutes(aEnd) > _toMinutes(bStart);
  }

  static int _toMinutes(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
  }
}