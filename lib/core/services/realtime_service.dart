import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'booking_hub.dart';
import 'notification_controller.dart';

/// Maintains a JWT-authenticated WebSocket to the backend's ``/api/ws``
/// endpoint and turns ``booking_changed`` pushes into [BookingHub] refreshes.
///
/// Reconnects with capped exponential backoff (2s → 4s → 8s → 16s → 32s) and
/// reads a fresh token from [TokenStorage] on every attempt, so a token
/// refresh performed by [ApiClient] is picked up automatically.
class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _stopped = true;
  int _attempt = 0;

  static const Duration _maxBackoff = Duration(seconds: 30);

  bool get isRunning => !_stopped && _channel != null;

  /// Starts (or restarts) the connection. Safe to call after [stop].
  Future<void> start() async {
    _stopped = false;
    _reconnectTimer?.cancel();
    _attempt = 0;
    await _connect();
  }

  Future<void> _connect() async {
    if (_stopped) return;

    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;

    final token = await TokenStorage.instance.readToken();
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }

    try {
      final base = ApiConstants.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final uri = Uri.parse(
        '$base/api/ws?token=${Uri.encodeQueryComponent(token)}',
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('RealtimeService: connect failed ($e)');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    _attempt = 0;
    if (data is! String) return;
    try {
      final json = jsonDecode(data);
      if (json is! Map) return;
      switch (json['type']) {
        case 'booking_changed':
          BookingHub.instance.invalidate();
          // A status change normally produces a notification right after, so
          // nudge the badge now rather than waiting for it to arrive.
          NotificationController.instance.refreshUnreadCount();
          break;
        case 'notification':
          // The push is a signal that something changed, not a payload to
          // trust; the controller refetches the authoritative feed.
          NotificationController.instance.onPushed();
          break;
      }
    } catch (_) {
      // Non-JSON frame (e.g. ping/pong) is ignored.
    }
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _channel = null;
    _subscription = null;
    final delay = _nextBackoff();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  Duration _nextBackoff() {
    final exp = 1 << (_attempt < 5 ? _attempt : 5);
    _attempt++;
    final seconds = exp > _maxBackoff.inSeconds ? _maxBackoff.inSeconds : exp;
    return Duration(seconds: seconds);
  }

  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _attempt = 0;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}