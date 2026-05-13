import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/reminder_settings.dart';
import '../../routes/app_routes.dart';
import '../../services/reminder_service.dart';
import '../../services/settings_service.dart';
import '../../services/vibration_service.dart';
import '../../theme/app_theme.dart';

/// Settings – corrections :
/// • Thème : source de vérité = themeModeNotifier (pas de désync avec Profile)
/// • Notifications : sauvegarde + sync immédiate
/// • Section "About" supprimée
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode        = true;
  bool _workoutReminder = false;
  bool _mealReminder    = false;
  bool _waterReminder   = false;
  bool _vibration       = true;
  bool _sound           = true;
  bool _loaded          = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Écoute les changements de thème (ex: si changé depuis un autre écran)
    SettingsService.themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    SettingsService.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      _darkMode = SettingsService.themeModeNotifier.value == ThemeMode.dark;
    });
  }

  Future<void> _loadSettings() async {
    // Thème : lire depuis le notifier (source de vérité unique)
    final mode = SettingsService.themeModeNotifier.value;
    final vib  = await SettingsService.isVibrationEnabled();
    final snd  = await SettingsService.isSoundEnabled();
    final wrk  = await SettingsService.isWorkoutReminderEnabled();
    final rem  = await ReminderService().load();

    if (!mounted) return;
    setState(() {
      _darkMode        = mode == ThemeMode.dark;
      _vibration       = vib;
      _sound           = snd;
      _workoutReminder = wrk;
      _mealReminder    = rem.mealReminderEnabled;
      _waterReminder   = rem.waterReminderEnabled;
      _loaded          = true;
    });
  }

  // ── Thème ──────────────────────────────────────────────────────────────────
  Future<void> _setDarkMode(bool v) async {
    setState(() => _darkMode = v);
    await SettingsService.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  Future<void> _setWorkoutReminder(bool v) async {
    setState(() => _workoutReminder = v);
    await SettingsService.setWorkoutReminderEnabled(v);
  }

  Future<void> _setMealReminder(bool v) async {
    setState(() => _mealReminder = v);
    await ReminderService().save(ReminderSettings(
      mealReminderEnabled: v, waterReminderEnabled: _waterReminder,
    ));
  }

  Future<void> _setWaterReminder(bool v) async {
    setState(() => _waterReminder = v);
    await ReminderService().save(ReminderSettings(
      mealReminderEnabled: _mealReminder, waterReminderEnabled: v,
    ));
  }

  // ── Feedback ───────────────────────────────────────────────────────────────
  Future<void> _setVibration(bool v) async {
    setState(() => _vibration = v);
    await SettingsService.setVibrationEnabled(v);
    if (v) await VibrationService.vibrate();
  }

  Future<void> _setSound(bool v) async {
    setState(() => _sound = v);
    await SettingsService.setSoundEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);

    if (!_loaded) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.fitGreen)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Settings',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.textPrimary : const Color(0xFF111111))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileCard(isDark: isDark),
          const SizedBox(height: 20),

          // ── Appearance ───────────────────────────────────────────────────
          _Section(
            title: 'Appearance', icon: Icons.palette_outlined, isDark: isDark,
            children: [
              _ToggleTile(
                label: 'Dark Mode',
                subtitle: _darkMode ? 'Currently: Dark' : 'Currently: Light',
                icon: _darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                value: _darkMode, onChanged: _setDarkMode, isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Notifications ─────────────────────────────────────────────────
          _Section(
            title: 'Notifications', icon: Icons.notifications_outlined, isDark: isDark,
            children: [
              _ToggleTile(
                label: 'Workout Reminder', subtitle: 'Get reminded to train',
                icon: Icons.fitness_center_outlined,
                value: _workoutReminder, onChanged: _setWorkoutReminder, isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _ToggleTile(
                label: 'Meal Reminder', subtitle: 'Daily at 1:00 PM',
                icon: Icons.restaurant_outlined,
                value: _mealReminder, onChanged: _setMealReminder, isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _ToggleTile(
                label: 'Hydration Reminder', subtitle: 'Every 2 hours (8 AM – 10 PM)',
                icon: Icons.water_drop_outlined,
                value: _waterReminder, onChanged: _setWaterReminder, isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Feedback ──────────────────────────────────────────────────────
          _Section(
            title: 'Feedback', icon: Icons.vibration_outlined, isDark: isDark,
            children: [
              _ToggleTile(
                label: 'Vibration', subtitle: 'Haptic feedback on actions',
                icon: Icons.vibration_outlined,
                value: _vibration, onChanged: _setVibration, isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _ToggleTile(
                label: 'Sound', subtitle: 'Audio feedback',
                icon: Icons.volume_up_outlined,
                value: _sound, onChanged: _setSound, isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Account (section "About" supprimée) ───────────────────────────
          _Section(
            title: 'Account', icon: Icons.person_outline_rounded, isDark: isDark,
            children: [
              _TapTile(
                label: 'Edit Profile', icon: Icons.edit_outlined,
                color: AppTheme.fitGreen, isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.editProfileScreen),
              ),
              _Divider(isDark: isDark),
              _TapTile(
                label: 'Sign Out', icon: Icons.logout_rounded,
                color: AppTheme.statusRed, isDark: isDark,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.authScreen, (route) => false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Composants ────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final bool isDark;
  const _ProfileCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ── Non cliquable : juste une apparence décorative ────────────────────
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.fitGreen.withAlpha(40), AppTheme.fitGreenMuted.withAlpha(30)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.fitGreen.withAlpha(80)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.fitGreen.withAlpha(40),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person_rounded, color: AppTheme.fitGreen, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Profile',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textPrimary : const Color(0xFF111111))),
            Text('View and edit your fitness profile',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        )),
        // Chevron supprimé – pas de navigation
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;

  const _Section({
    required this.title, required this.icon,
    required this.isDark, required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(icon, size: 16, color: AppTheme.fitGreen),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.fitGreen, letterSpacing: 0.5)),
            ]),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label, required this.subtitle, required this.icon,
    required this.value, required this.onChanged, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value ? AppTheme.fitGreen.withAlpha(25) : AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18,
              color: value ? AppTheme.fitGreen : AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textPrimary : const Color(0xFF111111))),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint)),
          ],
        )),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black,
          activeTrackColor: AppTheme.fitGreen,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withAlpha(60),
        ),
      ]),
    );
  }
}

class _TapTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TapTile({
    required this.label, required this.icon, required this.color,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25), borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                  color: color))),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withAlpha(150)),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1, indent: 64, endIndent: 16,
      color: isDark ? AppTheme.borderLight : const Color(0xFFEEEEEE),
    );
  }
}
