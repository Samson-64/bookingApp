import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../features/dashboard/screens/appointments_view.dart';
import '../../../features/dashboard/screens/my_bookings_view.dart';
import '../../../features/dashboard/screens/parking_view.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/spinner.dart';
import 'specialist_dashboard.dart';
import 'specialist_profile_view.dart';

class SpecialistShell extends StatefulWidget {
  static const String routeName = '/provider';

  const SpecialistShell({super.key});

  @override
  State<SpecialistShell> createState() => _SpecialistShellState();
}

class _SpecialistShellState extends State<SpecialistShell> {
  int _index = 0;
  AppUser? _profile;
  String? _error;

  static const _titles = [
    'Dashboard',
    'Book Appointment',
    'Parking',
    'My Bookings',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.start();
    _loadProfile();
  }

  @override
  void dispose() {
    RealtimeService.instance.stop();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _error = null);
    try {
      final profile = await AuthService.instance.fetchProfile();
      if (!mounted) return;
      if (profile == null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return;
      }
      if (!profile.isSpecialist) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
      setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _signOut() async {
    await RealtimeService.instance.stop();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(profile),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
      ),
    );
  }

  Widget _buildBody(AppUser? profile) {
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _loadProfile,
          child: const Text('Failed to load profile — tap to retry'),
        ),
      );
    }
    if (profile == null) {
      return const Spinner(label: 'Loading profile…');
    }

    return IndexedStack(
      index: _index,
      children: [
        ProviderDashboardView(user: profile),
        AppointmentsView(excludePersonId: profile.personId),
        const ParkingView(),
        MyBookingsView(user: profile),
        ProfileView(user: profile),
      ],
    );
  }
}