import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/under_construction.dart';

class HomeShell extends StatefulWidget {
  static const String routeName = '/home';

  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Appointments', 'Parking', 'My Bookings'];

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(index: _index, children: const [
        UnderConstruction(
          icon: Icons.space_dashboard_rounded,
          title: 'Dashboard Coming Soon',
          message: 'Your greeting, summary cards and booking overview will appear here.',
        ),
        UnderConstruction(
          icon: Icons.event_available_rounded,
          title: 'Appointments Coming Soon',
          message: 'Pick a provider, choose a date, and book a time window.',
        ),
        UnderConstruction(
          icon: Icons.local_parking_rounded,
          title: 'Parking Coming Soon',
          message: 'Browse parking levels and reserve a space.',
        ),
        UnderConstruction(
          icon: Icons.receipt_long_rounded,
          title: 'My Bookings Coming Soon',
          message: 'All your appointments and parking reservations will appear here.',
        ),
      ]),
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

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}