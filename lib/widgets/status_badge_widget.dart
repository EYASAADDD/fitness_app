import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFDBEAFE),
    this.textColor = const Color(0xFF1D4ED8),
    this.fontSize = 11,
  });

  factory StatusBadgeWidget.healthy() => const StatusBadgeWidget(
        label: 'Healthy',
        backgroundColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF15803D),
      );

  factory StatusBadgeWidget.warning(String label) => StatusBadgeWidget(
        label: label,
        backgroundColor: const Color(0xFFFEF3C7),
        textColor: const Color(0xFFB45309),
      );

  factory StatusBadgeWidget.danger(String label) => StatusBadgeWidget(
        label: label,
        backgroundColor: const Color(0xFFFEE2E2),
        textColor: const Color(0xFFB91C1C),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}