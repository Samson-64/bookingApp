import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/under_construction.dart';

class SpecialistDashboard extends StatefulWidget {
  static const String routeName = '/provider';

  const SpecialistDashboard({super.key});

  @override
  State<SpecialistDashboard> createState() => _SpecialistDashboardState();
}

class _SpecialistDashboardState extends State<SpecialistDashboard> {
  AppUser? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AuthService.instance.fetchProfile();
      if (!mounted) return;
      if (profile == null || !profile.isSpecialist) {
        Navigator.of(context).pushReplacementNamed('/home');
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
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
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
    );
  }

  Widget _buildBody(AppUser? profile) {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.indigo600,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, ${profile.name}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigo50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: AppColors.indigo600.withAlpha(80)),
                          ),
                          child: Text(
                            'Provider',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const UnderConstruction(
            icon: Icons.badge_rounded,
            title: 'Appointments Panel Coming Soon',
            message:
                'Review assigned appointments, verify them, and update status (Pending / Confirmed / Completed / Cancelled).',
          ),
        ],
      ),
    );
  }
}