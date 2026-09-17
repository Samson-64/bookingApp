import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/parking_service.dart';
import '../../../shared/models/parking_space_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/spinner.dart';
import '../../parking/screens/parking_floor_view.dart';

class ParkingView extends StatefulWidget {
  const ParkingView({super.key});

  @override
  State<ParkingView> createState() => _ParkingViewState();
}

class _ParkingViewState extends State<ParkingView> {
  List<ParkingSpace> _spaces = [];
  bool _loading = true;
  String? _error;

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
      _spaces = await ParkingService.instance.fetchSpaces();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, List<ParkingSpace>> get _grouped {
    final map = <String, List<ParkingSpace>>{};
    for (final s in _spaces) {
      final floor = s.location.isEmpty ? 'Unassigned' : s.location;
      map.putIfAbsent(floor, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Spinner(label: 'Loading parking…')
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _spaces.isEmpty
          ? const EmptyState(
              title: 'No parking floors available',
              icon: Icons.local_parking_outlined,
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final grouped = _grouped;
    final floors = grouped.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Parking Facilities',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select a floor to view available parking spaces.',
          style: TextStyle(fontSize: 13, color: AppColors.slate500),
        ),
        const SizedBox(height: 16),
        ...floors.map((floor) => _floorCard(floor, grouped[floor]!)),
      ],
    );
  }

  Widget _floorCard(String floor, List<ParkingSpace> spaces) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParkingFloorView(floor: floor, spaces: spaces),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_parking,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    floor.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    floor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spaces.length} Total Slot(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}
