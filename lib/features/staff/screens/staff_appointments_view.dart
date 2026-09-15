import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/spinner.dart';
import '../../../shared/widgets/status_badge.dart';

class StaffAppointmentsView extends StatefulWidget {
  final AppUser user;

  const StaffAppointmentsView({super.key, required this.user});

  @override
  State<StaffAppointmentsView> createState() => _StaffAppointmentsViewState();
}

class _StaffAppointmentsViewState extends State<StaffAppointmentsView> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  String _tab = 'PENDING';
  String? _busyId;

  static const _tabs = [
    ('PENDING', 'Pending Review'),
    ('CONFIRMED', 'Confirmed'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

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

  int _count(String status) =>
      _bookings.where((b) => b.status.name.toUpperCase() == status).length;

  List<Booking> get _filtered =>
      _bookings.where((b) => b.status.name.toUpperCase() == _tab).toList();

  Future<void> _updateStatus(Booking booking, String status) async {
    setState(() => _busyId = booking.id);
    try {
      await BookingService.instance.updateStatus(
        bookingId: booking.id,
        status: status,
      );
      if (mounted) {
        setState(() {
          _bookings = _bookings.map((b) => b.id == booking.id
              ? Booking.fromMap({
                  'id': b.id,
                  'userId': b.userId,
                  'type': b.type == BookingType.parking ? 'PARKING' : 'APPOINTMENT',
                  'status': status,
                  'date': dateKey(b.date),
                  'startTime': b.startTime,
                  'endTime': b.endTime,
                  'reference': b.reference,
                  'person': b.person?.toMap(),
                  'parking_space': b.space != null
                      ? {
                          'id': b.space!.id,
                          'name': b.space!.name,
                          'location': b.space!.location,
                          'available': b.space!.isAvailable,
                        }
                      : null,
                })
              : b)
          .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Portal: Schedule'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Spinner(label: 'Loading schedule…')
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filtered;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.indigo50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.indigo600.withAlpha(80)),
              ),
              child: const Text(
                'Staff Authorization Active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.indigo600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Review incoming booking requests, approve pending bookings, or mark appointments completed.',
          style: TextStyle(fontSize: 13, color: AppColors.slate500),
        ),
        const SizedBox(height: 16),
        _buildTabs(),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          EmptyState(
            title: 'No ${_tab.toLowerCase()} appointments',
            message: 'No appointment records currently match this status filter.',
            icon: Icons.schedule,
          )
        else
          ...filtered.map((b) => _appointmentCard(b)),
      ],
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
          final count = _count(key);
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? AppColors.slate900
                              : AppColors.slate500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.teal50
                            : AppColors.slate200,
                        borderRadius: BorderRadius.circular(6),
                        border: active
                            ? Border.all(color: AppColors.teal200)
                            : null,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? AppColors.teal700
                              : AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
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
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
        ],
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
                        const Icon(Icons.person,
                            size: 14, color: AppColors.slate400),
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
                          const Icon(Icons.mail_outline,
                              size: 14, color: AppColors.slate400),
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
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          '${formatLongDate(dateKey(b.date))} · ${b.startTime} – ${b.endTime}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate700,
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
          Divider(
            height: 1,
            color: Colors.grey.withAlpha(30),
          ),
          const SizedBox(height: 12),
          if (b.status == BookingStatus.pending)
            _actionRow(b, busy, onPrimary: () => _updateStatus(b, 'CONFIRMED'),
                primaryLabel: 'Accept Booking',
                onDanger: () => _updateStatus(b, 'CANCELLED'),
                dangerLabel: 'Cancel')
          else if (b.status == BookingStatus.confirmed)
            _actionRow(b, busy, onPrimary: () => _updateStatus(b, 'COMPLETED'),
                primaryLabel: 'Mark Completed',
                onDanger: () => _updateStatus(b, 'CANCELLED'),
                dangerLabel: 'Cancel')
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No further actions available',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionRow(
    Booking b,
    bool busy, {
    required VoidCallback onPrimary,
    required String primaryLabel,
    required VoidCallback onDanger,
    required String dangerLabel,
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
              onPressed: busy ? null : onDanger,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rose600,
                side: const BorderSide(color: Color(0xFFFDA4AF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(dangerLabel, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }
}