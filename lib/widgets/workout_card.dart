import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/workout_plan_item.dart';
import '../theme/app_theme.dart';

/// Reusable card for a single workout exercise
class WorkoutCard extends StatelessWidget {
  final WorkoutPlanItem item;
  final VoidCallback? onStart;
  final VoidCallback? onToggleDone;
  final VoidCallback? onDelete;

  const WorkoutCard({
    super.key,
    required this.item,
    this.onStart,
    this.onToggleDone,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.bgCard : Colors.white;
    final border = item.isCompleted ? AppTheme.fitGreen.withAlpha(120) : AppTheme.borderLight;

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
          children: [
            // ── Checkbox ──────────────────────────────────────────────────
            GestureDetector(
              onTap: onToggleDone,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isCompleted ? AppTheme.fitGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isCompleted ? AppTheme.fitGreen : AppTheme.textHint,
                    width: 2,
                  ),
                ),
                child: item.isCompleted
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
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: item.isCompleted
                          ? AppTheme.textHint
                          : (isDark ? AppTheme.textPrimary : const Color(0xFF111111)),
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip('${item.sets} sets', AppTheme.fitGreen),
                      const SizedBox(width: 6),
                      _chip('${item.reps} reps', AppTheme.statusBlue),
                      if (item.restSeconds > 0) ...[
                        const SizedBox(width: 6),
                        _chip('${item.restSeconds}s rest', AppTheme.textHint),
                      ],
                    ],
                  ),
                  if (item.targetMuscles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.targetMuscles.join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Actions ───────────────────────────────────────────────────
            Column(
              children: [
                if (onStart != null && !item.isCompleted)
                  _iconBtn(
                    icon: Icons.play_arrow_rounded,
                    color: AppTheme.fitGreen,
                    bg: AppTheme.fitGreen.withAlpha(25),
                    onTap: onStart!,
                    tooltip: 'Start',
                  ),
                if (onDelete != null) ...[
                  const SizedBox(height: 6),
                  _iconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.statusRed,
                    bg: AppTheme.statusRed.withAlpha(20),
                    onTap: onDelete!,
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
