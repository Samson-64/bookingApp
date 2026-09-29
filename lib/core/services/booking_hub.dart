import 'dart:async';

import 'package:flutter/foundation.dart';

/// App-wide signal that booking data may have changed.
///
/// Every screen that lists bookings listens to this hub and re-fetches when
/// it fires. It is notified by:
///   - success of local booking create / status-change calls
///   - ``booking_changed`` events pushed over the realtime WebSocket
///     (including changes made by other users, e.g. staff confirming one
///     of your appointments).
///
/// A short debounce coalesces bursts (a local call and the echo of its own
/// WebSocket event) into a single refresh so screens refresh once, not twice.
class BookingHub extends ChangeNotifier {
  BookingHub._();

  static final BookingHub instance = BookingHub._();

  static const Duration _debounce = Duration(milliseconds: 250);

  Timer? _timer;
  int _version = 0;

  /// Increments every time the booking data set is invalidated.
  int get version => _version;

  /// Schedules a single notification (debounced) to all listeners.
  void invalidate() {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      _version++;
      notifyListeners();
    });
  }
}