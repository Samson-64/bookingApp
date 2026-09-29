import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/notification_model.dart';
import 'notification_service.dart';

/// Owns the notification feed and the unread badge.
///
/// The badge is kept warm by the realtime push (see [RealtimeService]) so it
/// increments the moment a booking changes, instead of waiting for the next
/// screen visit. Mark-as-read and delete are applied optimistically and rolled
/// back if the request fails, because the badge is what the user is reading.
class NotificationController extends ChangeNotifier {
  NotificationController._();
  static final NotificationController instance = NotificationController._();

  NotificationService get _service => NotificationService.instance;

  List<AppNotification> _items = const [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  Timer? _coalesceTimer;

  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String get error => _error ?? '';
  bool get loaded => _loaded;

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final feed = await _service.fetchFeed();
      _items = feed.items;
      _unreadCount = feed.unreadCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  /// Called from the realtime service when the server pushes a notification.
  /// A single push usually arrives with the booking event that caused it, so
  /// bursts are coalesced into one refetch.
  void onPushed() {
    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  Future<void> refresh() async {
    try {
      final feed = await _service.fetchFeed();
      _items = feed.items;
      _unreadCount = feed.unreadCount;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Badge-only refresh, used when a booking change arrives before its
  /// notification does.
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _service.fetchUnreadCount();
      notifyListeners();
    } catch (_) {
      // A slightly stale badge is not worth an error banner.
    }
  }

  Future<void> markRead(String id) async {
    final previous = _items;
    final previousCount = _unreadCount;
    // Only decrement when the item was actually unread, or a repeat tap would
    // under-count.
    final wasUnread = _items.any((n) => n.id == id && !n.read);
    _items = _items
        .map((n) => n.id == id && !n.read
            ? AppNotification(
                id: n.id,
                category: n.category,
                title: n.title,
                body: n.body,
                bookingId: n.bookingId,
                read: true,
                createdAt: n.createdAt,
              )
            : n)
        .toList();
    if (wasUnread) _unreadCount = (_unreadCount - 1).clamp(0, 1 << 31);
    notifyListeners();
    try {
      await _service.markRead(id);
    } catch (e) {
      _error = e.toString();
      _items = previous;
      _unreadCount = previousCount;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final previous = _items;
    final previousCount = _unreadCount;
    _items = _items
        .map((n) => AppNotification(
              id: n.id,
              category: n.category,
              title: n.title,
              body: n.body,
              bookingId: n.bookingId,
              read: true,
              createdAt: n.createdAt,
            ))
        .toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markAllRead();
    } catch (e) {
      _error = e.toString();
      _items = previous;
      _unreadCount = previousCount;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    final previous = _items;
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();
    try {
      await _service.delete(id);
      await refreshUnreadCount();
    } catch (e) {
      _error = e.toString();
      _items = previous;
      notifyListeners();
    }
  }

  /// Clears state on sign-out so the next account starts from zero.
  void reset() {
    _coalesceTimer?.cancel();
    _coalesceTimer = null;
    _items = const [];
    _unreadCount = 0;
    _error = null;
    _loaded = false;
    notifyListeners();
  }
}
