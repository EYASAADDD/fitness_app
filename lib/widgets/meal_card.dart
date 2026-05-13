import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/meal_plan_item.dart';
import '../theme/app_theme.dart';

/// Reusable card for a single meal (To-Do style)
class MealCard extends StatelessWidget {
  final MealPlanItem item;
  final VoidCallback? onToggleConsumed;
  final VoidCallback? onDelete;

  const MealCard({
    super.key,
    required this.item,
    this.onToggleConsumed,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCard : Colors.white;
    final border = item.isConsumed ? AppTheme.fitGreen.withAlpha(120) : AppTheme.borderLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox ──────────────────────────────────────────────────
            GestureDetector(
              onTap: onToggleConsumed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isConsumed ? AppTheme.fitGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isConsumed ? AppTheme.fitGreen : AppTheme.textHint,
                    width: 2,
                  ),
                ),
                child: item.isConsumed
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _mealIcon(item.mealName),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.mealName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: item.isConsumed
                                ? AppTheme.textHint
                                : (isDark ? AppTheme.textPrimary : const Color(0xFF111111)),
                            decoration: item.isConsumed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (item.plannedHour != null)
                        Text(
                          item.plannedHour!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                    ],
                  ),
                  if (item.foods.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.foods.map((f) => f.name).join(', '),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.isConsumed && item.consumedAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.fitGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Consumed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.fitGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.statusRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.statusRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mealIcon(String mealName) {
    final lower = mealName.toLowerCase();
    IconData icon;
    Color color;
    if (lower.contains('break') || lower.contains('petit')) {
      icon = Icons.wb_sunny_rounded;
      color = AppTheme.statusOrange;
    } else if (lower.contains('lunch') || lower.contains('dejeuner')) {
      icon = Icons.wb_cloudy_rounded;
      color = AppTheme.statusBlue;
    } else if (lower.contains('dinner') || lower.contains('diner')) {
      icon = Icons.nights_stay_rounded;
      color = AppTheme.fitGreenMuted;
    } else {
      icon = Icons.restaurant_rounded;
      color = AppTheme.textHint;
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
