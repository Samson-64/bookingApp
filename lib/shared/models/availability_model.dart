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
    return Availability(
      working: map['working'] == true,
      scheduleStart: map['schedule_start']?.toString() ?? '09:00',
      scheduleEnd: map['schedule_end']?.toString() ?? '17:00',
      existing: (map['existing'] as List<dynamic>? ?? const [])
          .map((e) => TimeWindow(
                startTime: _norm(e is Map ? e['start_time'] : null),
                endTime: _norm(e is Map ? e['end_time'] : null),
              ))
          .toList(),
    );
  }

  static String _norm(dynamic v) {
    final s = v?.toString() ?? '00:00';
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