import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ScanResultSheetWidget extends StatefulWidget {
  final Map<String, dynamic> result;
  final List<String> userDiseases;
  final VoidCallback onClose;
  final VoidCallback onAddToLog;
  final VoidCallback onGetRecipes;

  const ScanResultSheetWidget({
    super.key,
    required this.result,
    required this.userDiseases,
    required this.onClose,
    required this.onAddToLog,
    required this.onGetRecipes,
  });

  @override
  State<ScanResultSheetWidget> createState() => _ScanResultSheetWidgetState();
}

class _ScanResultSheetWidgetState extends State<ScanResultSheetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  int _calculateHealthScore() {
    int score = 80;
    final calories = (widget.result['calories'] as num?)?.toInt() ?? 0;
    final sugar = (widget.result['sugar'] as num?)?.toDouble() ?? 0;
    final sodium = (widget.result['sodium'] as num?)?.toDouble() ?? 0;
    final fats = (widget.result['fats'] as num?)?.toDouble() ?? 0;

    if (calories < 50) score += 10;
    if (calories > 300) score -= 10;

    for (final disease in widget.userDiseases) {
      switch (disease.toLowerCase()) {
        case 'diabetes':
          if (sugar > 10) score -= 20;
          break;
        case 'hypertension':
          if (sodium > 200) score -= 20;
          break;
        case 'cholesterol':
          if (fats > 15) score -= 20;
          break;
      }
    }
    return score.clamp(0, 100);
  }

  List<Map<String, dynamic>> _generateAdvice() {
    final advice = <Map<String, dynamic>>[];
    final sugar = (widget.result['sugar'] as num?)?.toDouble() ?? 0;
    final sodium = (widget.result['sodium'] as num?)?.toDouble() ?? 0;
    final fats = (widget.result['fats'] as num?)?.toDouble() ?? 0;
    final calories = (widget.result['calories'] as num?)?.toInt() ?? 0;

    for (final disease in widget.userDiseases) {
      switch (disease.toLowerCase()) {
        case 'diabetes':
          if (sugar > 10) {
            advice.add({
              'message': 'High sugar — monitor intake for diabetes',
              'positive': false,
            });
          } else {
            advice.add({
              'message': 'Low sugar — suitable for diabetics',
              'positive': true,
            });
          }
          break;
        case 'hypertension':
          if (sodium > 200) {
            advice.add({
              'message': 'High sodium — avoid for hypertension',
              'positive': false,
            });
          } else {
            advice.add({
              'message': 'Low sodium — good for blood pressure',
              'positive': true,
            });
          }
          break;
        case 'cholesterol':
          if (fats > 15) {
            advice.add({
              'message': 'High fat — not ideal for cholesterol',
              'positive': false,
            });
          } else {
            advice.add({
              'message': 'Low fat — suitable for cholesterol management',
              'positive': true,
            });
          }
          break;
      }
    }

    if (calories < 100) {
      advice.add({
        'message': 'Low calorie — good for weight management',
        'positive': true,
      });
    }

    return advice;
  }

  Color _scoreColor(int score) {
    if (score >= 70) return AppTheme.statusGreen;
    if (score >= 40) return AppTheme.statusOrange;
    return AppTheme.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    final healthScore = _calculateHealthScore();
    final advice = _generateAdvice();
    final scoreColor = _scoreColor(healthScore);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detected',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                widget.result['name'] as String? ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.bgPage,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildNutritionCard()),
                          const SizedBox(width: 12),
                          _buildHealthScoreCard(healthScore, scoreColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (advice.isNotEmpty) ...[
                        Text(
                          'Health Insights',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...advice.map(
                          (adviceItem) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AdviceRow(
                              message: adviceItem['message'] as String,
                              isPositive: adviceItem['positive'] as bool,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onAddToLog,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add to Log',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onGetRecipes,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.bgSecondary,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withAlpha(77),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Get Recipes',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    final items = [
      {
        'label': 'Calories',
        'value': '${widget.result['calories'] ?? 0}',
        'unit': 'kcal',
      },
      {
        'label': 'Carbs',
        'value': '${widget.result['carbs'] ?? 0}',
        'unit': 'g',
      },
      {
        'label': 'Protein',
        'value': '${widget.result['proteins'] ?? 0}',
        'unit': 'g',
      },
      {'label': 'Fat', 'value': '${widget.result['fats'] ?? 0}', 'unit': 'g'},
      {
        'label': 'Sugar',
        'value': '${widget.result['sugar'] ?? 0}',
        'unit': 'g',
      },
      {
        'label': 'Sodium',
        'value': '${widget.result['sodium'] ?? 0}',
        'unit': 'mg',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgPage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per 100g',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${item['value']}${item['unit']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(int score, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withAlpha(38),
                  color: color,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$score',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Health\nScore',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score >= 70
                  ? '✅ Good'
                  : score >= 40
                      ? '⚠️ Fair'
                      : '❌ Poor',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceRow extends StatelessWidget {
  final String message;
  final bool isPositive;

  const _AdviceRow({required this.message, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppTheme.statusGreen : AppTheme.statusRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
