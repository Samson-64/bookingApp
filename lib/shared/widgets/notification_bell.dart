import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/notification_controller.dart';
import '../models/notification_model.dart';
import '../utils/format.dart';

/// App-bar bell with a live unread badge, mirroring the web dropdown so the
/// two clients behave the same way.
class NotificationBell extends StatefulWidget {
  /// Called when a notification with a booking is tapped, so the shell can
  /// send the user to their bookings.
  final VoidCallback? onOpenBooking;

  const NotificationBell({super.key, this.onOpenBooking});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  static const _previewCount = 5;

  Future<void> _openList() async {
    if (!_overlayController.isShowing) _overlayController.show();
    await NotificationController.instance.refresh();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    } else {
      _openList();
    }
  }

  void _close() {
    if (_overlayController.isShowing) _overlayController.hide();
  }

  @override
  void dispose() {
    if (_overlayController.isShowing) _overlayController.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (_) => _buildOverlay(),
      child: AnimatedBuilder(
        animation: NotificationController.instance,
        builder: (context, _) {
          final controller = NotificationController.instance;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: IconButton(
                  tooltip: controller.unreadCount > 0
                      ? 'Notifications, ${controller.unreadCount} unread'
                      : 'Notifications',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: _toggle,
                ),
              ),
              if (controller.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.indigo600,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      controller.unreadCount > 99
                          ? '99+'
                          : '${controller.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Renders the dropdown in the app's root [Overlay] instead of inside the
  /// app bar's `Stack`, so it is neither clipped by the toolbar's bounds nor
  /// unreachable by hit testing.
  Widget _buildOverlay() {
    final controller = NotificationController.instance;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: _buildPanel(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    NotificationController controller,
  ) {
    final preview = controller.items.take(_previewCount).toList();
    return SizedBox(
      width: 320,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  if (controller.unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        await controller.markAllRead();
                        if (mounted) setState(() {});
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: controller.loading && controller.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  : preview.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 28),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 26, color: AppColors.slate300),
                              SizedBox(height: 8),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Booking updates will show up here.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: preview.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.slate50),
                          itemBuilder: (context, i) => _NotificationRow(
                            preview[i],
                            widget.onOpenBooking,
                            onClose: _close,
                          ),
                        ),
            ),
            const Divider(height: 1),
            TextButton(
              onPressed: () {
                _close();
                Navigator.of(context).pushNamed('/notifications');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
              ),
              child: const Text(
                'View all notifications',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onOpenBooking;
  final VoidCallback onClose;

  const _NotificationRow(this.notification, this.onOpenBooking, {required this.onClose});

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (notification.category) {
      NotificationCategory.bookingStatus =>
        (Icons.event_rounded, AppColors.indigo600),
      NotificationCategory.newBooking =>
        (Icons.auto_awesome_rounded, AppColors.emerald600),
      NotificationCategory.reminder =>
        (Icons.alarm_rounded, AppColors.amber600),
      NotificationCategory.system => (Icons.info_outline_rounded, AppColors.slate600),
    };

    return InkWell(
      onTap: () {
        onClose();
        NotificationController.instance.markRead(notification.id);
        if (notification.bookingId != null) onOpenBooking?.call();
      },
      child: Container(
        color: notification.read
            ? Colors.white
            : AppColors.indigo50.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelative(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
