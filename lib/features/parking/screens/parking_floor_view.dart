import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/models/parking_space_model.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/error_state.dart';
import 'parking_booking_view.dart';

class ParkingFloorView extends StatefulWidget {
  final String floor;
  final List<ParkingSpace> spaces;

  const ParkingFloorView({
    super.key,
    required this.floor,
    required this.spaces,
  });

  @override
  State<ParkingFloorView> createState() => _ParkingFloorViewState();
}

class _ParkingFloorViewState extends State<ParkingFloorView> {
  DateTime _date = DateTime.now();
  String? _error;

  int get _availableCount =>
      widget.spaces.where((s) => s.isAvailable).length;

  Future<void> _changeDate(DateTime d) async {
    setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios,
                      size: 14, color: AppColors.teal600),
                  SizedBox(width: 4),
                  Text(
                    'Back to Floors',
                    style: TextStyle(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.floor.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick a date and choose an available parking bay to reserve.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.teal200),
                  ),
                  child: Text(
                    '$_availableCount Available',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            if (_error != null)
              ErrorState(message: _error!, onRetry: () {})
            else
              ...widget.spaces.map((s) => _slotCard(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 14, color: AppColors.teal600),
        const SizedBox(width: 8),
        const Text(
          'Date:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) _changeDate(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Text(
                formatShortDate(dateKey(_date)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotCard(ParkingSpace space) {
    final isAvail = space.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvail ? Colors.white : AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvail ? AppColors.slate200 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAvail ? AppColors.teal600 : AppColors.slate400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      space.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAvail ? AppColors.emerald50 : AppColors.rose50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAvail ? 'Available' : 'Occupied',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAvail ? AppColors.emerald600 : AppColors.rose600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Colors.grey.withAlpha(30),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: isAvail
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParkingBookingView(
                            space: space,
                            floor: widget.floor,
                            date: _date,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvail
                    ? AppColors.slate900
                    : AppColors.slate300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isAvail ? 'Book Space' : 'Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}