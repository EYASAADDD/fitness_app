import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/coach_plan_store.dart';
import '../../services/ocr_nutrition_import_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';

/// Standalone OCR nutrition import screen (accessible from Home quick actions)
class NutritionImportScreen extends StatefulWidget {
  const NutritionImportScreen({super.key});

  @override
  State<NutritionImportScreen> createState() => _NutritionImportScreenState();
}

class _NutritionImportScreenState extends State<NutritionImportScreen> {
  final _ocrService = OCRNutritionImportService();
  final _store = CoachPlanStore();
  NutritionImportResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scan({bool fromCamera = false}) async {
    setState(() => _loading = true);
    try {
      final picked = await _ocrService.pickImage(fromCamera: fromCamera);
      if (picked == null) return;

      final result = await _ocrService.extractMealPlanFromImage(picked.path);
      setState(() => _result = result);

      if (result.meals.isNotEmpty) {
        await _store.appendMealItems(result.meals);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.meals.length} meal(s) added to Nutrition ✓'),
            backgroundColor: AppTheme.fitGreen,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meals detected. Try a clearer image.'),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: const AppBarWidget(title: 'Scan Meals', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Instructions card ────────────────────────────────────────────
          _InfoCard(
            icon: Icons.camera_alt_rounded,
            color: AppTheme.statusOrange,
            title: 'Scan a Meal Plan',
            body: 'Take a photo or pick an image containing meals.\n'
                'Example: "Breakfast: Eggs, Banana"\n"Lunch: Rice, Chicken"',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // ── Scan buttons ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ScanButton(
                  label: 'Camera',
                  icon: Icons.camera_alt_rounded,
                  color: AppTheme.statusOrange,
                  loading: _loading,
                  onTap: () => _scan(fromCamera: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanButton(
                  label: 'Gallery',
                  icon: Icons.photo_library_rounded,
                  color: AppTheme.statusBlue,
                  loading: _loading,
                  onTap: () => _scan(fromCamera: false),
                ),
              ),
            ],
          ),
          // ── Results ──────────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text(
              _result!.meals.isEmpty
                  ? 'No meals detected'
                  : '${_result!.meals.length} meal(s) detected',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            ..._result!.meals.map((meal) => _MealResultTile(meal: meal, isDark: isDark)),
            if (_result!.rawText.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RawTextCard(text: _result!.rawText, isDark: isDark),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ScanButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealResultTile extends StatelessWidget {
  final dynamic meal;
  final bool isDark;

  const _MealResultTile({required this.meal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final foods = (meal.foods as List).map((f) => f.name as String).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: AppTheme.statusOrange, size: 18),
              const SizedBox(width: 8),
              Text(
                meal.mealName as String,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                ),
              ),
              if (meal.plannedHour != null) ...[
                const Spacer(),
                Text(
                  meal.plannedHour as String,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint),
                ),
              ],
            ],
          ),
          if (foods.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              foods,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _RawTextCard extends StatelessWidget {
  final String text;
  final bool isDark;

  const _RawTextCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardAlt : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Raw OCR text',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
