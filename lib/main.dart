import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'core/services/auth_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_shell.dart';
import 'features/provider/screens/specialist_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        SpecialistShell.routeName: (_) => const SpecialistShell(),
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

    final hasUser = await TokenStorage.instance.hasToken();
    if (!mounted) return;
    if (!hasUser) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }

    String route = HomeShell.routeName;
    try {
      final profile = await AuthService.instance.fetchProfile();
      if (profile?.isSpecialist ?? false) {
        route = SpecialistShell.routeName;
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