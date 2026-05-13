import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class BmiPreviewCardWidget extends StatelessWidget {
  final double bmi;
  final String bmiStatus;

  const BmiPreviewCardWidget({
    super.key,
    required this.bmi,
    required this.bmiStatus,
  });

  Color get _bmiColor {
    if (bmi < 18.5) return AppTheme.statusOrange;
    if (bmi < 25.0) return AppTheme.statusGreen;
    if (bmi < 30.0) return AppTheme.statusOrange;
    return AppTheme.statusRed;
  }

  double get _progressValue {
    return ((bmi - 10) / 30).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _bmiColor.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bmiColor.withAlpha(51)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your BMI',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _bmiColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiStatus,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _bmiColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: _bmiColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 6),
                child: Text(
                  'kg/m²',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFF22C55E),
                        Color(0xFFF59E0B),
                        Color(0xFFEF4444),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (_progressValue * (MediaQuery.of(context).size.width - 96))
                    .clamp(0, MediaQuery.of(context).size.width - 96),
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bmiColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: _bmiColor.withAlpha(77), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Underweight',
                style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textHint),
              ),
              Text(
                'Normal',
                style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textHint),
              ),
              Text(
                'Overweight',
                style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textHint),
              ),
              Text(
                'Obese',
                style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
