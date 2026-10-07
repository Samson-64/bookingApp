import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/notification_controller.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/spinner.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    NotificationController.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: AnimatedBuilder(
        animation: NotificationController.instance,
        builder: (context, _) {
          final controller = NotificationController.instance;

          if (controller.loading && !controller.loaded) {
            return const Spinner(label: 'Loading notifications…');
          }

          final visible = _showUnreadOnly
              ? controller.items.where((n) => !n.read).toList()
              : controller.items;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _header(controller),
                    const SizedBox(height: 12),
                    _filterRow(controller),
                    const SizedBox(height: 16),
                    if (controller.error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ErrorState(
                          message: controller.error,
                          onRetry: controller.refresh,
                        ),
                      ),
                    if (visible.isEmpty)
                      EmptyState(
                        icon: _showUnreadOnly
                            ? Icons.mark_email_read_outlined
                            : Icons.notifications_none_rounded,
                        title: _showUnreadOnly
                            ? 'No unread notifications'
                            : 'No notifications yet',
                        message: _showUnreadOnly
                            ? 'Everything here has been read.'
                            : 'When a booking is confirmed, changed or about to '
                                  'start, it will show up here.',
                      )
                    else
                      ...visible.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationCard(notification: n),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterRow(NotificationController controller) {
    Widget chip(String label, int count, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.slate900 : AppColors.slate500,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(
            'All',
            controller.items.length,
            !_showUnreadOnly,
            () => setState(() => _showUnreadOnly = false),
          ),
          chip(
            'Unread',
            controller.unreadCount,
            _showUnreadOnly,
            () => setState(() => _showUnreadOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _header(NotificationController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            controller.unreadCount > 0
                ? '${controller.unreadCount} unread'
                : "You're all caught up.",
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
        ),
        if (controller.unreadCount > 0)
          TextButton.icon(
            onPressed: controller.markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final (icon, tint, label) = switch (notification.category) {
      NotificationCategory.bookingStatus => (
        Icons.event_rounded,
        AppColors.accent,
        'Booking update',
      ),
      NotificationCategory.newBooking => (
        Icons.auto_awesome_rounded,
        AppColors.emerald600,
        'New booking',
      ),
      NotificationCategory.reminder => (
        Icons.alarm_rounded,
        AppColors.amber600,
        'Reminder',
      ),
      NotificationCategory.system => (
        Icons.info_outline_rounded,
        AppColors.slate600,
        'System',
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.read
              ? AppColors.slate200
              : AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelative(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.slate400,
                ),
                onPressed: () =>
                    NotificationController.instance.delete(notification.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notification.body,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
              const Spacer(),
              if (!notification.read)
                TextButton(
                  onPressed: () =>
                      NotificationController.instance.markRead(notification.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark as read',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
