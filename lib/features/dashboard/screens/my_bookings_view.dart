import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/spinner.dart';

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
    _load();
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

    list.sort((a, b) => '${b.date}${b.endTime}'
        .compareTo('${a.date}${a.endTime}'));
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
          ? const Spinner(label: 'Loading bookings…')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
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
                  color: active ? AppColors.teal600 : Colors.transparent,
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
                              : AppColors.teal50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: active
                                ? Colors.white
                                : AppColors.teal600,
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
                color: active ? AppColors.teal600 : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.teal600 : AppColors.slate200,
                ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _row('Category', isAppt ? 'Appointment' : 'Parking'),
                  _row('Status', b.status.name.toUpperCase()),
                  _row('Date', formatLongDate(dateKey(b.date))),
                  _row('Time', '${b.startTime} – ${b.endTime}'),
                  _row('Reference', b.reference),
                  if (b.person != null) _row('Provider', b.person!.name),
                  if (b.space != null) _row('Space', '${b.space!.name} (${b.space!.location})'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
              textAlign: TextAlign.end,
            ),
          ),
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
