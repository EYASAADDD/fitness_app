import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class HealthSummaryCardWidget extends StatelessWidget {
  final double bmi;
  final String bmiStatus;
  final List<String> diseases;

  const HealthSummaryCardWidget({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.diseases,
  });

  Color get _bmiColor {
    if (bmi < 18.5) return AppTheme.statusOrange;
    if (bmi < 25.0) return AppTheme.statusGreen;
    if (bmi < 30.0) return AppTheme.statusOrange;
    return AppTheme.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'More',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgPage,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _bmiColor.withAlpha(31),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: _bmiColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            bmi.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _bmiColor.withAlpha(31),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bmiStatus,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _bmiColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (diseases.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Conditions',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: diseases.map((d) => _DiseaseTag(label: d)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiseaseTag extends StatelessWidget {
  final String label;

  const _DiseaseTag({required this.label});

  IconData get _icon {
    switch (label.toLowerCase()) {
      case 'diabetes':
        return Icons.bloodtype_outlined;
      case 'hypertension':
        return Icons.trending_up_rounded;
      case 'hypotension':
        return Icons.trending_down_rounded;
      case 'cholesterol':
        return Icons.favorite_border_rounded;
      case 'anemia':
        return Icons.water_drop_outlined;
      case 'obesity':
        return Icons.scale_outlined;
      case 'heart problems':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.tagBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: AppTheme.tagBlueDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.tagBlueDark,
            ),
          ),
        ],
      ),
    );
  }
}
