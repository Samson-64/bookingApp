import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/spinner.dart';
import '../../../features/staff/screens/staff_appointments_view.dart';
import 'appointments_view.dart';
import 'dashboard_view.dart';
import 'my_bookings_view.dart';
import 'parking_view.dart';

class HomeShell extends StatefulWidget {
  static const String routeName = '/home';

  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  AppUser? _profile;
  String? _error;

  static const _titles = ['Dashboard', 'Appointments', 'Parking', 'My Bookings'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      if (profile.isSpecialist) {
        Navigator.of(context).pushReplacementNamed('/provider');
        return;
      }
      setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void _openStaffPortal() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffAppointmentsView(user: profile),
      ),
    );
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
          if (profile?.isStaff ?? false)
            IconButton(
              tooltip: 'Staff Portal',
              icon: const Icon(Icons.work_outline),
              onPressed: _openStaffPortal,
            ),
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
        DashboardView(user: profile),
        const AppointmentsView(),
        const ParkingView(),
        MyBookingsView(user: profile),
      ],
    );
  }
}