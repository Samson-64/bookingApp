import 'package:flutter/material.dart';

import '../../../features/dashboard/screens/appointments_view.dart';
import '../../../features/dashboard/screens/my_bookings_view.dart';
import '../../../features/dashboard/screens/parking_view.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/nav_shell.dart';
import 'specialist_dashboard.dart';
import 'specialist_profile_view.dart';

class SpecialistShell extends StatelessWidget {
  static const String routeName = '/provider';

  const SpecialistShell({super.key});

  @override
  Widget build(BuildContext context) {
    return NavShell(
      requireSpecialist: true,
      titles: const [
        'Dashboard',
        'Book Appointment',
        'Parking',
        'My Bookings',
        'Profile',
      ],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available_rounded),
          label: 'Book',
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
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      buildViews: (AppUser profile, void Function(int) goToTab) => [
        ProviderDashboardView(user: profile),
        AppointmentsView(excludePersonId: profile.personId),
        const ParkingView(),
        MyBookingsView(user: profile),
        ProfileView(user: profile),
      ],
    );
  }
}