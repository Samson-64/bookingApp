import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_model.dart';

enum _AuthMode { login, register }

enum _AccountType { client, provider }

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  _AccountType _accountType = _AccountType.client;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  void _selectAccountType(_AccountType type) {
    setState(() {
      _accountType = type;
      if (type == _AccountType.client) _positionController.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (_mode == _AuthMode.register && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (_mode == _AuthMode.register &&
        _accountType == _AccountType.provider &&
        _positionController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your position or specification.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_mode == _AuthMode.login) {
        await AuthService.instance.signInWithPassword(email, password);
        await _navigateAfterSignIn();
      } else {
        final userId = _accountType == _AccountType.provider
            ? await AuthService.instance.registerProvider(
                name: _nameController.text.trim(),
                position: _positionController.text.trim(),
                email: email,
                password: password,
              )
            : await AuthService.instance.registerClient(
                name: _nameController.text.trim(),
                email: email,
                password: password,
              );

        if (userId != null) {
          await _navigateAfterSignIn();
        } else {
          // Email confirmation required by Supabase.
          if (mounted) {
            _switchMode(_AuthMode.login);
            _showConfirmation();
          }
        }
      }
    } on AuthException catch (error) {
      debugPrint('AuthException: ${error.message}');
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      debugPrint('Unexpected Error: $error');
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateAfterSignIn() async {
    AppUser? profile;
    try {
      profile = await AuthService.instance.fetchProfile();
    } catch (_) {
      profile = null;
    }
    if (!mounted) return;
    final target = (profile?.isSpecialist ?? false) ? '/provider' : '/home';
    Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
  }

  void _showConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created. Please check your email to confirm, then sign in.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == _AuthMode.register;

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrandHeader(context),
                  const SizedBox(height: 28),
                  _buildHeading(context, isRegister),
                  const SizedBox(height: 16),
                  _buildModeTabs(context),
                  if (isRegister) ...[
                    const SizedBox(height: 20),
                    _buildAccountTypeToggle(context),
                  ],
                  const SizedBox(height: 20),
                  _buildForm(context, isRegister),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(context),
                  ],
                  const SizedBox(height: 20),
                  _buildSubmitButton(context),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing, you agree to use the portal responsibly',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate400,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.slate900,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.calendar_month_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          'Booking Portal',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.slate900,
                fontSize: 22,
              ),
        ),
      ],
    );
  }

  Widget _buildHeading(BuildContext context, bool isRegister) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRegister ? 'Create your account' : 'Welcome Back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.slate900,
                fontSize: 26,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          isRegister
              ? 'Start organising your bookings in just a few moments.'
              : 'Sign in to continue to your workspace.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate500,
                fontSize: 13,
              ),
        ),
      ],
    );
  }

  Widget _buildModeTabs(BuildContext context) {
    final tabs = [
      (_AuthMode.login, 'Sign In'),
      (_AuthMode.register, 'Create account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.map((entry) {
          final (mode, label) = entry;
          final active = _mode == mode;
          return Expanded(
            child: InkWell(
              onTap: () => _switchMode(mode),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.slate900 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.slate500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountTypeToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccountTypeCard(
            active: _accountType == _AccountType.client,
            icon: Icons.person_outline_rounded,
            title: 'Client',
            detail: 'Booking Service',
            onTap: () => _selectAccountType(_AccountType.client),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccountTypeCard(
            active: _accountType == _AccountType.provider,
            icon: Icons.badge_outlined,
            title: 'Provider',
            detail: 'Offer Service',
            onTap: () => _selectAccountType(_AccountType.provider),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isRegister) {
    return Column(
      children: [
        if (isRegister) ...[
          _AuthField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
        ],
        if (isRegister && _accountType == _AccountType.provider) ...[
          _AuthField(
            controller: _positionController,
            label: 'Position or specification',
            hint: 'Consultant, trainer, technician',
            icon: Icons.work_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
        ],
        _AuthField(
          controller: _emailController,
          label: 'Email address',
          hint: 'you@company.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your Password',
          icon: Icons.lock_outline_rounded,
          obscure: !_showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.password,
            AutofillHints.newPassword,
          ],
          suffix: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.slate400,
              size: 20,
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rose600.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.rose600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.rose600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final isRegister = _mode == _AuthMode.register;

    return ElevatedButton(
      onPressed: _loading ? null : _submit,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isRegister
                      ? (_accountType == _AccountType.provider
                          ? 'Create provider account'
                          : 'Create account')
                      : 'Sign In',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final List<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.slate400, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.active,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.teal50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.teal600 : AppColors.slate200,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: active ? AppColors.slate900 : AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  color: active ? Colors.white : AppColors.slate500, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}