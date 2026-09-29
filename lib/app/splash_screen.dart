import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/home_shell.dart';
import '../features/provider/screens/specialist_shell.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _entrance = Duration(milliseconds: 420);
  static const Duration _exit = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _captionOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _entrance);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _captionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    );
    _controller.forward();
    _decideRoute();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decideRoute() async {
    if (!await TokenStorage.instance.hasToken()) {
      if (mounted) _goTo(const LoginScreen());
      return;
    }

    Widget target = const HomeShell();
    try {
      final profile = await AuthService.instance.fetchProfile();
      if (profile?.isSpecialist ?? false) {
        target = const SpecialistShell();
      }
    } catch (_) {
      // Fall back to the client shell; profile loads there.
    }
    if (mounted) _goTo(target);
  }

  void _goTo(Widget target) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _exit,
        pageBuilder: (_, _, _) => target,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _captionOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Booking Portal',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
