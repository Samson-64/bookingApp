import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/models/availability_model.dart';
import '../../../shared/models/person_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/spinner.dart';

class AppointmentsView extends StatefulWidget {
  final String? excludePersonId;

  const AppointmentsView({super.key, this.excludePersonId});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  List<Person> _people = [];
  bool _loading = true;
  String? _error;

  Person? _selectedPerson;
  DateTime? _selectedDate;
  DateTime? _visibleMonth;
  Availability? _availability;
  String? _startTime;
  String? _endTime;
  bool _checking = false;
  bool _submitting = false;
  String? _submitError;
  _BookingResult? _result;

  static const _timeOptions = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _people = await BookingService.instance.fetchProviders();
      if (widget.excludePersonId != null) {
        _people =
            _people.where((p) => p.id != widget.excludePersonId).toList();
      }
      if (_people.isNotEmpty) _selectedPerson = _people.first;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkAvailability() async {
    if (_selectedPerson == null || _selectedDate == null) return;
    setState(() {
      _checking = true;
      _availability = null;
      _startTime = null;
      _endTime = null;
    });
    try {
      _availability = await BookingService.instance
          .fetchAppointmentAvailability(
            personId: _selectedPerson!.id,
            date: dateKey(_selectedDate!),
          );
    } catch (e) {
      _availability = const Availability(working: false);
    }
    if (mounted) setState(() => _checking = false);
  }

  bool get _canConfirm {
    return _selectedPerson != null &&
        _selectedDate != null &&
        _startTime != null &&
        _endTime != null &&
        _startTime != _endTime;
  }

  List<String> get _startOptions =>
      _timeOptions.sublist(0, _timeOptions.length - 1);

  List<String> get _endOptions {
    if (_startTime == null) return _timeOptions.sublist(1);
    final idx = _timeOptions.indexOf(_startTime!);
    return _timeOptions.sublist(idx + 1);
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final booking = await BookingService.instance.createAppointment(
        userId: '',
        personId: _selectedPerson!.id,
        date: dateKey(_selectedDate!),
        startTime: _startTime!,
        endTime: _endTime!,
      );
      if (mounted) {
        setState(() {
          _result = _BookingResult(
            reference: booking.reference,
            personName: booking.person?.name ?? _selectedPerson!.name,
            personPosition:
                booking.person?.position ?? _selectedPerson!.position,
            date: dateKey(_selectedDate!),
            startTime: _startTime!,
            endTime: _endTime!,
            status: booking.status.name.toUpperCase(),
          );
        });
      }
    } catch (e) {
      setState(() => _submitError = e.toString());
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.rose600,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  _submitError ?? 'Failed to book',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.rose600,
                  ),
                ),
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
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _showSummarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Confirm Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 16),
            _summaryRow('Provider', _selectedPerson?.name ?? ''),
            _summaryRow('Role', _selectedPerson?.position ?? ''),
            _summaryRow(
              'Date',
              _selectedDate != null
                  ? formatLongDate(dateKey(_selectedDate!))
                  : '',
            ),
            _summaryRow(
              'Time',
              _startTime != null && _endTime != null
                  ? '$_startTime – $_endTime'
                  : '',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.pop(context);
                        _confirm();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : const Text('Confirm Appointment'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
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

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildSuccess();

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Spinner(label: 'Loading providers…')
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _buildWizard(),
    );
  }

  Widget _buildWizard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Book an Appointment',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 16),

        // Step 1: Provider
        _stepHeader(1, 'Select Provider'),
        const SizedBox(height: 8),
        ..._people.map((p) => _providerCard(p)),
        const SizedBox(height: 20),

        // Step 2: Date
        _stepHeader(2, 'Select Date'),
        const SizedBox(height: 8),
        _buildCalendar(),
        if (_selectedDate != null) ...[
          const SizedBox(height: 4),
          Text(
            formatLongDate(dateKey(_selectedDate!)),
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
        ],
        const SizedBox(height: 20),

        // Step 3: Time
        _stepHeader(3, 'Choose Time Window'),
        const SizedBox(height: 8),
        if (_checking)
          const Spinner(label: 'Checking provider availability…')
        else if (_availability == null)
          const EmptyState(
            title: 'Pick a provider and date to see times',
            icon: Icons.schedule,
          )
        else if (!_availability!.working)
          const EmptyState(
            title: 'Provider is not available on this date',
            icon: Icons.event_busy,
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.teal600),
                const SizedBox(width: 8),
                Text(
                  'Working hours: ${_availability!.scheduleStart} – ${_availability!.scheduleEnd}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal700,
                  ),
                ),
              ],
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canConfirm ? _showSummarySheet : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Review & Confirm'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    final r = _result!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.teal50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.teal200),
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
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Booked Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reference: ${r.reference}',
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow('Provider', r.personName),
              _detailRow('Role', r.personPosition),
              _detailRow('Date', formatLongDate(r.date)),
              _detailRow('Time', '${r.startTime} – ${r.endTime}'),
              _detailRow('Status', r.status),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _result = null;
                      _startTime = null;
                      _endTime = null;
                      _availability = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Book Another'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepHeader(int num, String label) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.slate900,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$num',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }

  Widget _providerCard(Person p) {
    final selected = _selectedPerson?.id == p.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPerson = p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.slate50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.slate900 : AppColors.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.slate900 : AppColors.slate900,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.slate500,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    p.position,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.slate900,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  static const _weekdayLabels = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const _monthLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Widget _buildCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = _visibleMonth ?? DateTime(today.year, today.month);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7;
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: isCurrentMonth
                      ? null
                      : () => setState(() {
                          _visibleMonth = DateTime(month.year, month.month - 1);
                        }),
                  icon: const Icon(Icons.chevron_left, size: 22),
                  color: AppColors.slate600,
                  disabledColor: AppColors.slate300,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Text(
                    '${_monthLabels[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _visibleMonth = DateTime(month.year, month.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right, size: 22),
                  color: AppColors.slate600,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: _weekdayLabels
                  .map(
                    (d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.slate100),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (int day = 1; day <= daysInMonth; day++)
                  _buildDayCell(
                    date: DateTime(month.year, month.month, day),
                    today: today,
                    selectedDate: _selectedDate,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required DateTime today,
    required DateTime? selectedDate,
  }) {
    final isToday = dateKey(date) == dateKey(today);
    final isSelected =
        selectedDate != null && dateKey(date) == dateKey(selectedDate);
    final isPast = date.isBefore(today);
    final enabled = !isPast;

    return GestureDetector(
      onTap: enabled
          ? () async {
              setState(() => _selectedDate = date);
              await _checkAvailability();
            }
          : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: (isSelected || isToday)
                ? BoxShape.circle
                : BoxShape.rectangle,
            color: isSelected
                ? AppColors.slate900
                : isToday
                ? AppColors.slate100
                : null,
            border: isToday && !isSelected
                ? Border.all(color: AppColors.slate900, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppColors.slate900
                      : enabled
                      ? AppColors.slate900
                      : AppColors.slate300,
                ),
              ),
              if (isToday && !isSelected)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.slate600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
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
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
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
}

class _BookingResult {
  final String reference;
  final String personName;
  final String personPosition;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  const _BookingResult({
    required this.reference,
    required this.personName,
    required this.personPosition,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });
}
