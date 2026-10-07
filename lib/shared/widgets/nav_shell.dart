import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/notification_controller.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/settings_controller.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/staff/screens/staff_appointments_view.dart';
import '../models/user_model.dart';
import '../widgets/error_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/spinner.dart';

/// Shared tab shell for the client and provider experiences: loads the
/// profile, guards the entrance route, and renders the app bar, NavigationBar
/// and IndexedStack used by both [HomeShell] and [SpecialistShell].
class NavShell extends StatefulWidget {
  const NavShell({
    super.key,
    required this.titles,
    required this.destinations,
    required this.buildViews,
    this.requireSpecialist = false,
    this.showStaffAction = false,
    this.bookingsTab = 3,
  });

  final List<String> titles;
  final List<NavigationDestination> destinations;

  /// Builds one view per tab, given the loaded profile and a way to switch
  /// tabs (used by the dashboard's "book now" shortcuts).
  final List<Widget> Function(AppUser profile, void Function(int) goToTab)
      buildViews;

  /// When true the shell bounces clients out to `/home` (provider shell).
  final bool requireSpecialist;
  final bool showStaffAction;
  final int bookingsTab;

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;
  AppUser? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.start();
    // Warm the cached preferences and the unread badge once, here, so the
    // booking screens can read them without a request of their own.
    SettingsController.instance.load();
    NotificationController.instance.load();
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
      if (widget.requireSpecialist && !profile.isSpecialist) {
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
      if (!widget.requireSpecialist && profile.isSpecialist) {
        Navigator.of(context).pushReplacementNamed('/provider');
        return;
      }
      setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _signOut() async {
    await RealtimeService.instance.stop();
    SettingsController.instance.reset();
    NotificationController.instance.reset();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void _openSettings() {
    Navigator.of(context).pushNamed(SettingsScreen.routeName);
  }

  void _openMyBookings() {
    setState(() => _index = widget.bookingsTab);
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

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titles[_index]),
        actions: [
          if (widget.showStaffAction && (profile?.isStaff ?? false))
            IconButton(
              tooltip: 'Staff Portal',
              icon: const Icon(Icons.work_outline),
              onPressed: _openStaffPortal,
            ),
          NotificationBell(onOpenBooking: _openMyBookings),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
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
        destinations: widget.destinations,
      ),
    );
  }

  Widget _buildBody(AppUser? profile) {
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _loadProfile);
    }
    if (profile == null) {
      return const Spinner(label: 'Loading profile…');
    }
    return IndexedStack(
      index: _index,
      children: widget.buildViews(profile, _goToTab),
    );
  }
}