import 'package:flutter/material.dart';

import 'app/splash_screen.dart';
import 'app/theme.dart';
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
