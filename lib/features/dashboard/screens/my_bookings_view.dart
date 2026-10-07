import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/booking_hub.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/booking_summary_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeleton.dart';

class MyBookingsView extends StatefulWidget {
  final AppUser user;
  const MyBookingsView({super.key, required this.user});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  _StatusTab _statusTab = _StatusTab.upcoming;
  _TypeFilter _typeFilter = _TypeFilter.all;

  @override
  void initState() {
    super.initState();
    BookingHub.instance.addListener(_onBookingChanged);
    _load();
  }

  @override
  void dispose() {
    BookingHub.instance.removeListener(_onBookingChanged);
    super.dispose();
  }

  void _onBookingChanged() => _reload();

  /// Soft refresh: updates the list in place without flashing the spinner.
  Future<void> _reload() async {
    try {
      final bookings = await BookingService.instance.fetchMyBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted && _bookings.isEmpty) setState(() => _error = e.toString());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _bookings = await BookingService.instance.fetchMyBookings();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Booking> get _filtered {
    var list = _bookings.where((b) {
      if (_statusTab == _StatusTab.upcoming) return b.isUpcoming;
      if (_statusTab == _StatusTab.pending) return b.isPending;
      if (_statusTab == _StatusTab.completed) return b.isCompleted;
      if (_statusTab == _StatusTab.cancelled) return b.isCancelled;
      return true;
    }).toList();

    if (_typeFilter == _TypeFilter.appointment) {
      list = list.where((b) => b.type == BookingType.appointment).toList();
    } else if (_typeFilter == _TypeFilter.parking) {
      list = list.where((b) => b.type == BookingType.parking).toList();
    }

    list.sort(
      (a, b) => '${b.date}${b.endTime}'.compareTo('${a.date}${a.endTime}'),
    );
    return list;
  }

  int _count(_StatusTab tab) => _bookings.where((b) {
    if (tab == _StatusTab.upcoming) return b.isUpcoming;
    if (tab == _StatusTab.pending) return b.isPending;
    if (tab == _StatusTab.completed) return b.isCompleted;
    if (tab == _StatusTab.cancelled) return b.isCancelled;
    return true;
  }).length;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const BookingListSkeleton()
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('My Bookings', style: AppType.pageTitle),
            const SizedBox(height: 4),
            const Text(
              'Track and manage your reservations.',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            _buildStatusTabs(),
            const SizedBox(height: 12),
            _buildTypeFilter(),
            const SizedBox(height: 12),
            if (_filtered.isEmpty)
              EmptyState(
                title: 'No ${_statusTab.label.toLowerCase()} reservations',
                icon: Icons.bookmark_border,
              )
            else
              ..._filtered.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookingCard(
                    booking: b,
                    onViewDetails: () => _showDetail(b),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _StatusTab.values.map((tab) {
          final active = _statusTab == tab;
          final count = _count(tab);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _statusTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.slate500,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withAlpha(30)
                              : AppColors.slate50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Row(
      children: _TypeFilter.values.map((f) {
        final active = _typeFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _typeFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.slate500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDetail(Booking b) {
    final isAppt = b.type == BookingType.appointment;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingSummarySheet(
        title: 'Booking Details',
        monoValues: const {'Reference'},
        rows: [
          ('Category', isAppt ? 'Appointment' : 'Parking'),
          ('Status', b.status.name),
          ('Date', formatLongDate(dateKey(b.date))),
          ('Time', '${b.startTime} – ${b.endTime}'),
          ('Reference', b.reference),
          if (b.person != null) ('Provider', b.person!.name),
          if (b.space != null)
            ('Space', '${b.space!.name} (${b.space!.location})'),
        ],
      ),
    );
  }
}

enum _StatusTab {
  upcoming('Upcoming'),
  pending('Pending'),
  completed('Completed'),
  cancelled('Cancelled');

  const _StatusTab(this.label);
  final String label;
}

enum _TypeFilter {
  all('All'),
  appointment('Appointments'),
  parking('Parking');

  const _TypeFilter(this.label);
  final String label;
}
