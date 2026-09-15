import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/booking_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/spinner.dart';

class DashboardView extends StatefulWidget {
  final AppUser user;
  const DashboardView({super.key, required this.user});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  _Tab _tab = _Tab.all;

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
    final list = _tab == _Tab.all
        ? _bookings
        : _bookings.where((b) => b.type == _tab.type).toList();
    list.sort((a, b) => '${b.date}${b.endTime}'
        .compareTo('${a.date}${a.endTime}'));
    return list;
  }

  int get _todayCount => _bookings
      .where((b) => dateKey(b.date) == todayLocalStr())
      .length;

  int get _upcomingApptCount => _bookings
      .where((b) => b.isUpcoming && b.type == BookingType.appointment)
      .length;

  int get _upcomingParkingCount => _bookings
      .where((b) => b.isUpcoming && b.type == BookingType.parking)
      .length;

  int get _confirmedCount =>
      _bookings.where((b) => b.isConfirmed).length;

  String get _greeting => greeting();

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
        // Header
        Text(
          '$_greeting, ${widget.user.name}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 16),
        // Metric cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            MetricCard(
              label: "TODAY'S",
              value: '$_todayCount',
              icon: Icons.calendar_today,
              hero: true,
              footer: '${_bookings.where((b) => b.isUpcoming).length} upcoming',
              footerAction: 'View ›',
            ),
            MetricCard(
              label: 'APPOINTMENTS',
              value: '$_upcomingApptCount',
              icon: Icons.trending_up,
              iconBg: AppColors.emerald50,
              iconFg: AppColors.emerald600,
              footer: 'Scheduled',
              footerAction: 'Book →',
            ),
            MetricCard(
              label: 'PARKING',
              value: '$_upcomingParkingCount',
              icon: Icons.local_parking,
              footer: 'Multi-floor',
              footerAction: 'Browse →',
            ),
            MetricCard(
              label: 'CONFIRMED',
              value: '$_confirmedCount',
              icon: Icons.check_circle_outline,
              footer: 'All-time',
              footerAction: 'History →',
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Tab bar
        _buildTabBar(),
        const SizedBox(height: 12),
        // Booking list
        if (_filtered.isEmpty)
          EmptyState(
            title: 'No bookings found',
            message: 'Your upcoming and past bookings will appear here.',
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Book Now'),
            ),
          )
        else
          ..._filtered.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BookingCard(
                booking: b,
                onViewDetails: () => _showDetail(b),
                onBookAgain: () {},
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          _tabBtn('All', _Tab.all),
          _tabBtn('Appointments', _Tab.appointment),
          _tabBtn('Parking', _Tab.parking),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, _Tab tab) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.slate900 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.slate500,
            ),
          ),
        ),
      ),
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
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Category', isAppt ? 'Appointment' : 'Parking'),
                  _detailRow('Status', b.status.name),
                  _detailRow('Date', formatLongDate(dateKey(b.date))),
                  _detailRow('Time', '${b.startTime} – ${b.endTime}'),
                  _detailRow('Reference', b.reference, mono: true),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
                fontFamily: mono ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tab {
  all,
  appointment,
  parking,
}

extension _TabExt on _Tab {
  BookingType? get type => switch (this) {
        _Tab.all => null,
        _Tab.appointment => BookingType.appointment,
        _Tab.parking => BookingType.parking,
      };
}
