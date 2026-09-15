import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/parking_service.dart';
import '../../../shared/models/availability_model.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/parking_space_model.dart';
import '../../../shared/utils/format.dart';

class ParkingBookingView extends StatefulWidget {
  final ParkingSpace space;
  final String floor;
  final DateTime date;

  const ParkingBookingView({
    super.key,
    required this.space,
    required this.floor,
    required this.date,
  });

  @override
  State<ParkingBookingView> createState() => _ParkingBookingViewState();
}

class _ParkingBookingViewState extends State<ParkingBookingView> {
  late DateTime _date;
  String? _startTime;
  String? _endTime;

  Availability? _availability;
  bool _checking = false;
  bool _submitting = false;
  String? _error;
  Booking? _result;

  static const _times = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.date;
    _startTime = _times.first;
    _endTime = _times.length > 1 ? _times[1] : null;
  }

  List<String> get _startOptions => _times.sublist(0, _times.length - 1);

  List<String> get _endOptions {
    if (_startTime == null) return const [];
    final idx = _times.indexOf(_startTime!);
    return _times.sublist(idx + 1);
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _checking = true;
      _availability = null;
      _error = null;
    });
    try {
      final a = await ParkingService.instance.fetchAvailability(
        spaceId: widget.space.id,
        date: dateKey(_date),
      );
      setState(() => _availability = a);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _checking = false);
  }

  bool get _windowOccupied {
    final a = _availability;
    if (a == null || !a.working) return true;
    return a.intersects(_startTime!, _endTime!);
  }

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await BookingService.instance.createParkingBooking(
        userId: '',
        spaceId: widget.space.id,
        date: dateKey(_date),
        startTime: _startTime!,
        endTime: _endTime!,
      );
      if (mounted) setState(() => _result = booking);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildSuccess(_result!);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios,
                    size: 14, color: AppColors.teal600),
                const SizedBox(width: 4),
                Text(
                  'Back to ${widget.floor}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal600,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserve Space ${widget.space.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.space.location} · Reserved client parking',
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

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCHEDULE TIME WINDOW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                const Text(
                  'RESERVATION DATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      setState(() {
                        _date = d;
                        _availability = null;
                        _error = null;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.slate500),
                        const SizedBox(width: 8),
                        Text(
                          formatLongDate(dateKey(_date)),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _timeDropdown(
                        label: 'Start Time',
                        value: _startTime,
                        options: _startOptions,
                        onChanged: (v) => setState(() {
                          _startTime = v;
                          _endTime = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeDropdown(
                        label: 'End Time',
                        value: _endTime,
                        options: _endOptions,
                        onChanged: (v) => setState(() => _endTime = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _checking
                          ? null
                          : _checkAvailability,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate700,
                        side: const BorderSide(color: AppColors.slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify Slot Open',
                              style: TextStyle(fontSize: 13),
                            ),
                    ),
                    const SizedBox(width: 12),
                    if (_availability != null && !_checking)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _windowOccupied
                              ? AppColors.rose50
                              : AppColors.emerald50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _windowOccupied
                              ? 'Window Occupied'
                              : 'Window Available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _windowOccupied
                                ? AppColors.rose600
                                : AppColors.emerald600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUMMARY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow('Bay', widget.space.name),
                _summaryRow('Location', widget.space.location),
                _summaryRow(
                  'Time Slot',
                  _endTime != null ? '$_startTime – $_endTime' : '—',
                ),
                _summaryRow(
                  'Date',
                  formatLongDate(dateKey(_date)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _submitting || _startTime == null || _endTime == null
                            ? null
                            : _confirm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Reservation'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.rose600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccess(Booking booking) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.teal600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parking Space Reserved!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking Pass: ${booking.reference}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 20),
                _summaryRow('Space Name', widget.space.name),
                _summaryRow('Floor / Level', widget.floor),
                _summaryRow(
                  'Date',
                  formatLongDate(dateKey(booking.date)),
                ),
                _summaryRow(
                  'Reserved Hours',
                  '${booking.startTime} – ${booking.endTime}',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slate200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text('Select', style: TextStyle(fontSize: 13)),
              style: const TextStyle(fontSize: 13, color: AppColors.slate900),
              items: options
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.slate400,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}