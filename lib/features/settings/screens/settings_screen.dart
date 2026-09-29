import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/settings_controller.dart';
import '../../../core/services/settings_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../../shared/models/user_settings_model.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/spinner.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _durations = [15, 30, 45, 60, 90, 120];
  static const _reminderLeads = [15, 30, 60, 120, 240, 1440];

  // Local editable copies, committed per section rather than all at once.
  late UserSettings _draft;
  bool _seeded = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _floorController = TextEditingController();

  bool _savingPreferences = false;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _revoking = false;
  String? _preferencesError;
  String? _profileError;
  String? _passwordError;
  String? _sessionsError;

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _floorController.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _seed(UserSettings settings) async {
    if (_seeded) return;
    _seeded = true;
    _draft = settings;
    final profile = await AuthService.instance.fetchProfile();
    if (!mounted) return;
    _nameController.text = profile?.name ?? '';
    _emailController.text = profile?.email ?? '';
  }

  String? get _passwordProblem {
    if (_newPassword.text.isNotEmpty && _newPassword.text.length < 8) {
      return 'New password must be at least 8 characters';
    }
    if (_confirmPassword.text.isNotEmpty &&
        _newPassword.text != _confirmPassword.text) {
      return 'The two passwords do not match';
    }
    return null;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _savePreferences() async {
    setState(() {
      _savingPreferences = true;
      _preferencesError = null;
    });
    try {
      final floor = _floorController.text.trim();
      final next = await SettingsController.instance.save({
        'notifyBookingUpdates': _draft.notifyBookingUpdates,
        'notifyNewBookings': _draft.notifyNewBookings,
        'notifyReminders': _draft.notifyReminders,
        'reminderMinutesBefore': _draft.reminderMinutesBefore,
        'quietHoursEnabled': _draft.quietHoursEnabled,
        'quietHoursStart': _draft.quietHoursStart,
        'quietHoursEnd': _draft.quietHoursEnd,
        'language': _draft.language,
        'timezone': _draft.timezone,
        'defaultDurationMinutes': _draft.defaultDurationMinutes,
        // An empty box clears the preference; the backend treats an explicit
        // null differently from an omitted field.
        'preferredParkingFloor': floor.isEmpty ? null : floor,
      });
      if (!mounted) return;
      setState(() {
        _draft = next;
        _savingPreferences = false;
      });
      _toast('Settings saved');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingPreferences = false;
        _preferencesError = e.toString();
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      await SettingsService.instance.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _savingProfile = false);
      _toast('Profile updated');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _profileError = e.toString();
      });
    }
  }

  Future<void> _changePassword() async {
    if (_passwordProblem != null) return;
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    try {
      await SettingsService.instance.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      // Every session was revoked, including this one.
      await _signOutEverywhere();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _passwordError = e.toString();
      });
    }
  }

  Future<void> _revokeSessions() async {
    setState(() {
      _revoking = true;
      _sessionsError = null;
    });
    try {
      await SettingsService.instance.logoutEverywhere();
      if (!mounted) return;
      await _signOutEverywhere();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _revoking = false;
        _sessionsError = e.toString();
      });
    }
  }

  Future<void> _signOutEverywhere() async {
    await RealtimeService.instance.stop();
    SettingsController.instance.reset();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  String _leadLabel(int minutes) {
    if (minutes >= 1440) return '1 day before';
    if (minutes >= 60) {
      return '${minutes ~/ 60} hour${minutes > 60 ? 's' : ''} before';
    }
    return '$minutes minutes before';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: AnimatedBuilder(
        animation: SettingsController.instance,
        builder: (context, _) {
          final controller = SettingsController.instance;
          final settings = controller.settings;

          if (settings == null) {
            if (controller.loading || !controller.loaded) {
              return const Spinner(label: 'Loading settings…');
            }
            return Center(
              child: TextButton(
                onPressed: () => controller.load(force: true),
                child: Text(
                  controller.error ?? 'Failed to load settings — tap to retry',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Seed the editable copies once the server value is available.
          WidgetsBinding.instance.addPostFrameCallback((_) => _seed(settings));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _section(
                step: 1,
                title: 'Account',
                subtitle: 'Your name and email address.',
                children: [
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email address'),
                  ),
                  if (_profileError != null) ...[
                    const SizedBox(height: 10),
                    _errorText(_profileError!),
                  ],
                  const SizedBox(height: 14),
                  _saveButton(
                    label: 'Update profile',
                    busy: _savingProfile,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                step: 2,
                title: 'Notifications',
                subtitle: 'Choose what you hear about, and when.',
                children: [
                  _switchRow(
                    label: 'Booking updates',
                    description:
                        'When one of your bookings is confirmed, completed or cancelled.',
                    value: _draft.notifyBookingUpdates,
                    onChanged: (v) => setState(() => _draft =
                        _draft.copyWith(notifyBookingUpdates: v)),
                  ),
                  _switchRow(
                    label: 'New bookings',
                    description: 'When a new appointment is assigned to you.',
                    value: _draft.notifyNewBookings,
                    onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(notifyNewBookings: v)),
                  ),
                  _switchRow(
                    label: 'Reminders',
                    description: 'A nudge shortly before a booking starts.',
                    value: _draft.notifyReminders,
                    onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(notifyReminders: v)),
                  ),
                  if (_draft.notifyReminders) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _draft.reminderMinutesBefore,
                      decoration: const InputDecoration(labelText: 'Remind me'),
                      items: _reminderLeads
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_leadLabel(m)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _draft =
                          _draft.copyWith(reminderMinutesBefore: v ?? 60)),
                    ),
                  ],
                  const Divider(height: 28),
                  _switchRow(
                    label: 'Quiet hours',
                    description:
                        'Hold reminders during these hours. Booking updates are always kept.',
                    value: _draft.quietHoursEnabled,
                    onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(quietHoursEnabled: v)),
                  ),
                  if (_draft.quietHoursEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _timeField(
                            label: 'From',
                            value: _draft.quietHoursStart,
                            onChanged: (v) => setState(
                                () => _draft = _draft.copyWith(quietHoursStart: v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _timeField(
                            label: 'Until',
                            value: _draft.quietHoursEnd,
                            onChanged: (v) => setState(
                                () => _draft = _draft.copyWith(quietHoursEnd: v)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _section(
                step: 3,
                title: 'Booking defaults',
                subtitle: 'Pre-selected when you make a new booking.',
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _draft.defaultDurationMinutes,
                    decoration:
                        const InputDecoration(labelText: 'Default duration'),
                    items: _durations
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m minutes'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _draft =
                        _draft.copyWith(defaultDurationMinutes: v ?? 60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _floorController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred parking floor',
                      hintText: 'e.g. Ground',
                      helperText: 'Leave blank for no preference.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _draft.timezone,
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      helperText: 'IANA name, e.g. Africa/Johannesburg',
                    ),
                    onChanged: (v) =>
                        setState(() => _draft = _draft.copyWith(timezone: v)),
                  ),
                  if (_preferencesError != null) ...[
                    const SizedBox(height: 10),
                    _errorText(_preferencesError!),
                  ],
                  const SizedBox(height: 14),
                  _saveButton(
                    label: 'Save preferences',
                    busy: _savingPreferences,
                    onPressed: _savePreferences,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                step: 4,
                title: 'Security',
                subtitle: 'Password and active sessions.',
                children: [
                  TextField(
                    controller: _currentPassword,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Current password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassword,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'New password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPassword,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      helperText: 'Changing your password signs you out '
                          'everywhere, including this device.',
                      errorText: _passwordProblem,
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 10),
                    _errorText(_passwordError!),
                  ],
                  const SizedBox(height: 14),
                  _saveButton(
                    label: 'Update password',
                    busy: _savingPassword,
                    onPressed: _changePassword,
                    enabled: _currentPassword.text.isNotEmpty &&
                        _newPassword.text.isNotEmpty &&
                        _confirmPassword.text.isNotEmpty &&
                        _passwordProblem == null,
                  ),
                  const Divider(height: 28),
                  const Text(
                    'Sign out of all devices',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ends every active session, including this one.',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                  if (_sessionsError != null) ...[
                    const SizedBox(height: 10),
                    _errorText(_sessionsError!),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _revoking ? null : _revokeSessions,
                    icon: _revoking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out everywhere'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose600,
                      side: const BorderSide(color: AppColors.rose600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (v) {
        final text = v ?? '';
        return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(text)
            ? null
            : 'Use HH:MM';
      },
    );
  }

  Widget _errorText(String message) => Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.rose600,
        ),
      );

  Widget _saveButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: enabled && !busy ? onPressed : null,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _section({
    required int step,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.slate900,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
