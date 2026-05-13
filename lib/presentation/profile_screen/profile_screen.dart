import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/user_profile_store.dart';
import '../../routes/app_routes.dart';
import '../../services/coach_plan_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _navIndex = 4;
  AppUserProfile _profile = AppUserProfile.defaults;
  final _coachStore = CoachPlanStore();
  DashboardCoachStats _stats = const DashboardCoachStats(
    totalWorkoutItems: 0,
    completedWorkoutItems: 0,
    totalMeals: 0,
    consumedMeals: 0,
    caloriesConsumed: 0,
    proteins: 0,
    carbs: 0,
    fat: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileStore.load();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _loadStats() async {
    final stats = await _coachStore.loadDashboardStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (route) => false,
      );
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Respecte le thème actuel (dark ou light) au lieu de forcer bgPage
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildSectionTitle('Data'),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.edit_rounded,
              title: 'Edit fitness profile',
              subtitle: 'Update weight, height, goal and level',
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfileScreen),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Theme, language and notifications',
              onTap: () => Navigator.pushNamed(context, AppRoutes.settingsScreen),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.history_rounded,
              title: 'History',
              subtitle: 'Workout and meal history',
              onTap: () => Navigator.pushNamed(context, AppRoutes.historyScreen),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.favorite_rounded,
              title: 'Favorites',
              subtitle: 'Favorite exercises and meals',
              onTap: () => Navigator.pushNamed(context, AppRoutes.historyScreen),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.download_rounded,
              title: 'Export progress',
              subtitle: 'Generate a PDF summary of training and nutrition',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.logout_rounded,
              title: 'Reset session',
              subtitle: 'Clear local onboarding data and return to welcome',
              onTap: _resetLocalData,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.bgCard,
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile & Progress',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Goals, metrics and preferences',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue.withAlpha(18), AppTheme.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profile.name,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Age ${_profile.age} • ${_profile.height.toStringAsFixed(0)} cm • ${_profile.weight.toStringAsFixed(0)} kg',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricBadge('BMI', _profile.bmi.toStringAsFixed(1)),
              const SizedBox(width: 10),
              _metricBadge('Status', _profile.bmiStatus),
              const SizedBox(width: 10),
              _metricBadge('Focus', _profile.diseases.isNotEmpty ? _profile.diseases.first : 'Fitness'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StaticStatCard(label: 'Workout done', value: '${_stats.completedWorkoutItems}/${_stats.totalWorkoutItems}'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StaticStatCard(label: 'Calories meals', value: '${_stats.caloriesConsumed}'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _metricBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetLocalData() async {
    await FirebaseAuth.instance.signOut();
    await UserProfileStore.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.authScreen, (route) => false);
  }
}

class _StaticStatCard extends StatelessWidget {
  const _StaticStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
