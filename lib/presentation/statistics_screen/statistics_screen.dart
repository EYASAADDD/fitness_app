import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _navIndex = 3;
  String _period = 'week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Statistics',
                    style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ),
                DropdownButton<String>(
                  value: _period,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                  ],
                  onChanged: (value) => setState(() => _period = value ?? 'week'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _metricGrid(),
            const SizedBox(height: 18),
            _card('Progress overview', 'Weight, BMI, calories burned and completed sessions.'),
            const SizedBox(height: 12),
            _chartCard('Workout streak', 'Weekly workout streak chart will appear here.'),
            const SizedBox(height: 12),
            _chartCard('Nutrition charts', 'Calories, protein and water graphs for the selected period.'),
            const SizedBox(height: 12),
            _card('Workout statistics', 'Most performed exercises, total reps and training time.'),
            const SizedBox(height: 12),
            _card('Nutrition statistics', 'Weekly calories, protein and hydration tracking.'),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: _navIndex, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (route) => false);
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.recipesScreen);
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.searchScreen);
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
      return;
    }
    setState(() => _navIndex = index);
  }

  Widget _metricGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        _MetricCard(label: 'Current weight', value: '76.4 kg', icon: Icons.monitor_weight_rounded),
        _MetricCard(label: 'BMI', value: '23.1', icon: Icons.speed_rounded),
        _MetricCard(label: 'Calories burned', value: '1,920', icon: Icons.local_fire_department_rounded),
        _MetricCard(label: 'Completed sessions', value: '18', icon: Icons.check_circle_rounded),
      ],
    );
  }

  Widget _card(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _chartCard(String title, String subtitle) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [AppTheme.primaryBlue.withAlpha(14), AppTheme.bgCard]),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Icon(Icons.show_chart_rounded, color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const Spacer(),
          Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
