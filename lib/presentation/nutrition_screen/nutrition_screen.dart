import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../models/meal_plan_item.dart';
import '../../services/coach_plan_store.dart';
import '../../services/ocr_nutrition_import_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/meal_card.dart';
import '../../widgets/empty_state_widget.dart';

/// Nutrition tab – To-Do list of meals + OCR scan
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _store = CoachPlanStore();
  final _ocrService = OCRNutritionImportService();
  List<MealPlanItem> _items = [];
  bool _loading = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
    _loadItems();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await _store.loadMealItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _toggleConsumed(MealPlanItem item) async {
    await _store.markMealConsumed(item.id, consumed: !item.isConsumed);
    await _loadItems();
  }

  Future<void> _deleteItem(MealPlanItem item) async {
    final items = await _store.loadMealItems();
    final updated = items.where((e) => e.id != item.id).toList();
    await _store.saveMealItems(updated);
    await _loadItems();
  }

  Future<void> _scanMeals() async {
    setState(() => _scanning = true);
    try {
      final picked = await _ocrService.pickImage(fromCamera: false);
      if (picked == null) return;

      final result = await _ocrService.extractMealPlanFromImage(picked.path);

      if (result.meals.isEmpty) {
        if (!mounted) return;
        _showSnack('No meals detected. Try a clearer image.', isError: true);
        return;
      }

      await _store.appendMealItems(result.meals);
      await _loadItems();

      if (!mounted) return;
      _showSnack('${result.meals.length} meal(s) added from scan ✓');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addManually() async {
    final result = await showDialog<MealPlanItem>(
      context: context,
      builder: (_) => const _AddMealDialog(),
    );
    if (result != null) {
      await _store.appendMealItems([result]);
      await _loadItems();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Clear all?', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
        content: Text(
          'This will delete all meals.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.statusRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _store.saveMealItems([]);
      await _loadItems();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.statusRed : AppTheme.fitGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);
    final consumed = _items.where((e) => e.isConsumed).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Nutrition',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
          ),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.statusRed),
              tooltip: 'Clear all',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Action bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: _scanning ? 'Scanning…' : 'Scan Meals',
                    icon: Icons.camera_alt_rounded,
                    color: AppTheme.statusOrange,
                    onTap: _scanning ? null : _scanMeals,
                    loading: _scanning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Add Meal',
                    icon: Icons.add_rounded,
                    color: AppTheme.fitGreen,
                    onTap: _addManually,
                  ),
                ),
              ],
            ),
          ),
          // ── Summary ─────────────────────────────────────────────────────
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SummaryBar(consumed: consumed, total: _items.length, isDark: isDark),
            ),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.fitGreen))
                : _items.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.restaurant_rounded,
                        title: 'No meals yet',
                        description: 'Scan a meal plan image or add meals manually.',
                        ctaLabel: 'Scan Meals',
                        onCta: _scanMeals,
                      )
                    : RefreshIndicator(
                        color: AppTheme.fitGreen,
                        onRefresh: _loadItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return MealCard(
                              item: item,
                              onToggleConsumed: () => _toggleConsumed(item),
                              onDelete: () => _deleteItem(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int consumed;
  final int total;
  final bool isDark;

  const _SummaryBar({required this.consumed, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : consumed / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$consumed / $total meals consumed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.statusOrange),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add meal dialog ──────────────────────────────────────────────────────────

class _AddMealDialog extends StatefulWidget {
  const _AddMealDialog();

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  String _mealType = 'Breakfast';
  final _foodsCtrl = TextEditingController();

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _foodsCtrl.dispose();
    super.dispose();
  }

  String _defaultHour(String meal) {
    switch (meal) {
      case 'Breakfast':
        return '08:00';
      case 'Lunch':
        return '13:00';
      case 'Snack':
        return '17:00';
      default:
        return '20:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Add Meal',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal type',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _mealTypes.map((type) {
                final selected = _mealType == type;
                return GestureDetector(
                  onTap: () => setState(() => _mealType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.fitGreen : AppTheme.bgCardAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.fitGreen : AppTheme.borderLight,
                      ),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _foodsCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Foods (comma separated)',
                hintText: 'e.g. Eggs, Banana, Oats',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final foodNames = _foodsCtrl.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final foods = foodNames
                .map((name) => MealFoodItem(name: name))
                .toList();

            Navigator.pop(
              context,
              MealPlanItem(
                id: const Uuid().v4(),
                mealName: _mealType,
                foods: foods,
                estimatedCalories: 0,
                plannedHour: _defaultHour(_mealType),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
