import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/spinner.dart';
import '../../../shared/widgets/status_badge.dart';

class ProviderDashboardView extends StatefulWidget {
  final AppUser user;

  const ProviderDashboardView({super.key, required this.user});

  @override
  State<ProviderDashboardView> createState() => _ProviderDashboardViewState();
}

class _ProviderDashboardViewState extends State<ProviderDashboardView> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  String _tab = 'ALL';
  String? _busyId;

  static const _tabs = [
    ('ALL', 'All'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _bookings = await BookingService.instance.fetchSpecialistBookings(
        widget.user.personId ?? '',
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  int _count(String status) => status == 'ALL'
      ? _bookings.length
      : _bookings.where((b) => b.status.name.toUpperCase() == status).length;

  int get _upcomingConfirmed => _bookings
      .where((b) => b.status == BookingStatus.confirmed && b.isUpcoming)
      .length;

  List<Booking> get _filtered => _tab == 'ALL'
      ? _bookings
      : _bookings.where((b) => b.status.name.toUpperCase() == _tab).toList();

  Future<void> _updateStatus(Booking booking, String status) async {
    setState(() => _busyId = booking.id);
    try {
      await BookingService.instance.updateSpecialistStatus(
        bookingId: booking.id,
        status: status,
      );
      if (mounted) {
        setState(() {
          _bookings = _bookings
              .map(
                (b) => b.id == booking.id
                    ? Booking.fromMap({
                        'id': b.id,
                        'userId': b.userId,
                        'type': b.type == BookingType.parking
                            ? 'PARKING'
                            : 'APPOINTMENT',
                        'status': status,
                        'date': dateKey(b.date),
                        'startTime': b.startTime,
                        'endTime': b.endTime,
                        'reference': b.reference,
                        'person': b.person?.toMap(),
                      })
                    : b,
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (_error != null && _bookings.isEmpty) {
      return ErrorState(message: _error!, onRetry: _loadBookings);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.indigo600,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome back, ${user.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metric cards
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'PENDING REVIEW',
                  value: '${_count('PENDING')}',
                  icon: Icons.assignment_outlined,
                  iconBg: AppColors.amber50,
                  iconFg: AppColors.amber600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'UPCOMING \nCONFIRMED',
                  value: '$_upcomingConfirmed',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(
            label: 'TOTAL ASSIGNED',
            value: '${_count('ALL')}',
            icon: Icons.group_outlined,
            iconBg: AppColors.indigo50,
            iconFg: AppColors.indigo600,
          ),
          const SizedBox(height: 20),

          // Tabs
          _buildTabs(),
          const SizedBox(height: 16),

          if (_loading)
            const Spinner(label: 'Loading your appointments…')
          else if (_error != null)
            ErrorState(message: _error!, onRetry: _loadBookings)
          else if (_filtered.isEmpty)
            EmptyState(
              title: _tab == 'ALL'
                  ? 'No appointments assigned yet'
                  : 'No ${_tab.toLowerCase()} appointments',
              message: _tab == 'ALL'
                  ? 'When a client books an appointment with you, it will appear here for you to review and update.'
                  : 'No appointment records currently match this status filter.',
              icon: Icons.event_available_outlined,
            )
          else
            ..._filtered.map((b) => _appointmentCard(b)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _tabs.map((t) {
          final (key, label) = t;
          final active = _tab == key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.slate900 : AppColors.slate500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _appointmentCard(Booking b) {
    final busy = _busyId == b.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.group,
                  color: AppColors.teal600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.person?.name ?? 'Provider',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b.person?.position ?? 'Provider',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Client: ${b.clientName ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                    if (b.clientEmail?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              b.clientEmail!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${formatLongDate(dateKey(b.date))} · ${b.startTime} – ${b.endTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${b.reference}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: b.status.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withAlpha(30)),
          const SizedBox(height: 12),
          if (b.status == BookingStatus.pending)
            _actionRow(
              busy,
              primaryLabel: 'Verify & Confirm',
              onPrimary: () => _updateStatus(b, 'CONFIRMED'),
              secondaryLabel: 'Cancel',
              onSecondary: () => _updateStatus(b, 'CANCELLED'),
            )
          else if (b.status == BookingStatus.confirmed)
            _actionRow(
              busy,
              primaryLabel: 'Mark Completed',
              onPrimary: () => _updateStatus(b, 'COMPLETED'),
              secondaryLabel: 'Cancel',
              onSecondary: () => _updateStatus(b, 'CANCELLED'),
            ),
        ],
      ),
    );
  }

  Widget _actionRow(
    bool busy, {
    required String primaryLabel,
    required VoidCallback onPrimary,
    required String secondaryLabel,
    required VoidCallback onSecondary,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: busy ? null : onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primaryLabel, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: busy ? null : onSecondary,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rose600,
                side: const BorderSide(color: Color(0xFFFDA4AF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(secondaryLabel, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }
}
