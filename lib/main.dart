import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_shell.dart';
import 'features/provider/screens/specialist_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.anonKey,
  );

  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeShell.routeName: (_) => const HomeShell(),
        SpecialistDashboard.routeName: (_) => const SpecialistDashboard(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final hasUser = Supabase.instance.client.auth.currentUser != null;
    if (!hasUser) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }

    String route = HomeShell.routeName;
    try {
      final profile = await AuthService.instance.fetchProfile();
      if (profile?.isSpecialist ?? false) {
        route = SpecialistDashboard.routeName;
      }
    } catch (_) {
      // Fall back to the client shell; profile loads there.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 64, color: AppColors.slate900),
            SizedBox(height: 16),
            Text('Booking Portal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                )),
            SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}