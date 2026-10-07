import 'package:flutter/material.dart';

import 'app/splash_screen.dart';
import 'app/theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_shell.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/provider/screens/specialist_shell.dart';
import 'features/settings/screens/settings_screen.dart';
import 'shared/widgets/empty_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeShell.routeName: (_) => const HomeShell(),
        SpecialistShell.routeName: (_) => const SpecialistShell(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        NotificationsScreen.routeName: (_) => const NotificationsScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => const PageNotFoundScreen(),
          settings: settings,
        );
      },
    );
  }
}

class PageNotFoundScreen extends StatelessWidget {
  const PageNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                title: 'Page not found',
                message: 'That screen does not exist in this workspace.',
                icon: Icons.explore_off_outlined,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
