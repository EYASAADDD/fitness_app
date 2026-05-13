import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Respecte le thème actuel ──────────────────────────────────────────
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppTheme.bgPage     : const Color(0xFFF5F5F5);
    final cardBg  = isDark ? AppTheme.bgCard      : Colors.white;
    final textCol = isDark ? AppTheme.textPrimary : const Color(0xFF111111);

    final workoutHistory = [
      ('Upper body', '4 sets • 32 reps • 28 min', 'Today'),
      ('Leg day',    '5 sets • 48 reps • 42 min', 'Yesterday'),
    ];
    final mealHistory = [
      ('Lunch',     '650 kcal • Chicken rice bowl', 'Today'),
      ('Breakfast', '420 kcal • Eggs and banana',   'Yesterday'),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: textCol),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _section('Workout History', workoutHistory,
              Icons.fitness_center_rounded, AppTheme.fitGreen,
              isDark: isDark, cardBg: cardBg, textCol: textCol),
          const SizedBox(height: 16),
          _section('Meal History', mealHistory,
              Icons.restaurant_rounded, AppTheme.statusOrange,
              isDark: isDark, cardBg: cardBg, textCol: textCol),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<(String, String, String)> items,
    IconData icon,
    Color accent, {
    required bool isDark,
    required Color cardBg,
    required Color textCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textCol,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history_rounded, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: textCol)),
                  Text(item.$2,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              )),
              Text(item.$3,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textHint)),
            ]),
          )),
        ],
      ),
    );
  }
}
