import 'package:flutter/material.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/nav_shell.dart';
import 'appointments_view.dart';
import 'dashboard_view.dart';
import 'my_bookings_view.dart';
import 'parking_view.dart';

class HomeShell extends StatelessWidget {
  static const String routeName = '/home';

  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return NavShell(
      titles: const ['Dashboard', 'Appointments', 'Parking', 'My Bookings'],
      showStaffAction: true,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available_rounded),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_parking_outlined),
          selectedIcon: Icon(Icons.local_parking_rounded),
          label: 'Parking',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'My Bookings',
        ),
      ],
      buildViews: (AppUser profile, void Function(int) goToTab) => [
        DashboardView(user: profile, onNavigateToTab: goToTab),
        const AppointmentsView(),
        const ParkingView(),
        MyBookingsView(user: profile),
      ],
    );
  }
}