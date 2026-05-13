import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/user_profile_store.dart';
import '../../routes/app_routes.dart';
import '../../services/coach_plan_store.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUserProfile _profile = AppUserProfile.defaults;
  final _store = CoachPlanStore();
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
    _load();
  }

  Future<void> _load() async {
    final profile = await UserProfileStore.load();
    final stats = await _store.loadDashboardStats();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _stats = stats;
    });
  }

  // ── Greeting selon l'heure ─────────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Message motivationnel dynamique selon l'heure ──────────────────────────
  String get _motivationalMessage {
    final h = DateTime.now().hour;
    if (h < 9) return 'Start your day strong 💪';
    if (h < 12) return 'Morning session? Let\'s go! 🔥';
    if (h < 14) return 'Fuel up and keep moving 🍽️';
    if (h < 17) return 'Afternoon grind, stay focused 🎯';
    if (h < 20) return 'Evening workout time! 🌙';
    return 'Rest well, train harder tomorrow ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.fitGreen,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(isDark),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    // ── Option B : Motivational + Quick Scan ──────────────
                    _buildMotivationalCard(isDark),
                    const SizedBox(height: 20),
                    // ── Stats séparées Workouts Done / Meals Done ─────────
                    _buildStatsRow(isDark),
                    const SizedBox(height: 24),
                    _sectionTitle('Quick Actions', isDark),
                    const SizedBox(height: 12),
                    _buildQuickActions(isDark),
                    const SizedBox(height: 24),
                    _sectionTitle('Today\'s Progress', isDark),
                    const SizedBox(height: 12),
                    _buildProgressCard(isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader(bool isDark) {
    return SliverAppBar(
      backgroundColor: isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.fitGreen.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.fitGreen.withAlpha(80)),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppTheme.fitGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_greeting 👋',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                _profile.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsScreen),
          icon: Icon(
            Icons.settings_outlined,
            color: isDark ? AppTheme.textSecondary : const Color(0xFF555555),
          ),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Carte verte motivationnelle (style "Start Live Session") ─────────────
  Widget _buildMotivationalCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8F135), Color(0xFF9DC41A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Message motivationnel uniquement ──────────────────────────
          Expanded(
            child: Text(
              _motivationalMessage,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Icône coureur ─────────────────────────────────────────────
          Icon(
            Icons.directions_run_rounded,
            size: 72,
            color: Colors.black.withAlpha(180),
          ),
        ],
      ),
    );
  }

  // ── Stats row : Workouts Done + Meals Done séparés ─────────────────────────
  Widget _buildStatsRow(bool isDark) {
    // Taux de complétion workouts
    final workoutRate = _stats.totalWorkoutItems == 0
        ? 0
        : ((_stats.completedWorkoutItems / _stats.totalWorkoutItems) * 100).round();
    // Taux de complétion meals
    final mealRate = _stats.totalMeals == 0
        ? 0
        : ((_stats.consumedMeals / _stats.totalMeals) * 100).round();

    return Row(
      children: [
        // ── Workouts Done ──────────────────────────────────────────────────
        Expanded(
          child: _StatCard(
            icon: Icons.fitness_center_rounded,
            iconColor: AppTheme.fitGreen,
            label: 'Workouts Done',
            value: '${_stats.completedWorkoutItems}',
            sub: 'of ${_stats.totalWorkoutItems}  •  $workoutRate%',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        // ── Meals Done ────────────────────────────────────────────────────
        Expanded(
          child: _StatCard(
            icon: Icons.restaurant_rounded,
            iconColor: AppTheme.statusOrange,
            label: 'Meals Done',
            value: '${_stats.consumedMeals}',
            sub: 'of ${_stats.totalMeals}  •  $mealRate%',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ── Quick Actions grid ─────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      _ActionItem('Scan Workout', Icons.document_scanner_rounded, AppTheme.fitGreen, AppRoutes.workoutImportScreen),
      _ActionItem('Scan Meals', Icons.camera_alt_rounded, AppTheme.statusOrange, AppRoutes.nutritionImportScreen),
      _ActionItem('History', Icons.history_rounded, AppTheme.fitGreenMuted, AppRoutes.historyScreen),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, a.route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: a.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icon, color: a.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Today's Progress ──────────────────────────────────────────────────────
  Widget _buildProgressCard(bool isDark) {
    final total = _stats.totalWorkoutItems + _stats.totalMeals;
    final done = _stats.completedWorkoutItems + _stats.consumedMeals;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Completion',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.fitGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.fitGreen),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dot(AppTheme.fitGreen, '${_stats.completedWorkoutItems} workouts done'),
              const SizedBox(width: 16),
              _dot(AppTheme.statusOrange, '${_stats.consumedMeals} meals consumed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

/// Carte stat individuelle (Workouts Done / Meals Done)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionItem(this.label, this.icon, this.color, this.route);
}
