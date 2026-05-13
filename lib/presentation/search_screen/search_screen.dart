import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/meal_plan_item.dart';
import '../../routes/app_routes.dart';
import '../../services/coach_plan_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _navIndex = 3;
  final _store = CoachPlanStore();
  final _searchController = TextEditingController();

  List<MealPlanItem> _meals = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    final loaded = await _store.loadMealItems();
    if (!mounted) return;
    setState(() {
      _meals = loaded;
      _loading = false;
    });
  }

  Future<void> _toggleConsumed(MealPlanItem item) async {
    await _store.markMealConsumed(item.id, consumed: !item.isConsumed);
    await _loadMeals();
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
    if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.statisticsScreen);
      return;
    }
    setState(() => _navIndex = index);
  }

  List<MealPlanItem> get _filteredMeals {
    if (_query.trim().isEmpty) return _meals;
    final q = _query.toLowerCase();
    return _meals.where((meal) {
      final inMeal = meal.mealName.toLowerCase().contains(q);
      final inFoods = meal.foods.any((f) => f.name.toLowerCase().contains(q));
      return inMeal || inFoods;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final consumed = _meals.where((e) => e.isConsumed).length;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nutrition',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.nutritionImportScreen),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentBlue.withAlpha(28), AppTheme.bgCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentBlue.withAlpha(90)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan alimentaire importe',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Repas consommes: $consumed/${_meals.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un repas ou aliment...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredMeals.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Text(
                  'Aucun repas. Va sur Nutrition Import puis Scanner Meal Plan.',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              )
            else
              ..._filteredMeals.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MealCard(
                    meal: meal,
                    onToggle: () => _toggleConsumed(meal),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onToggle});

  final MealPlanItem meal;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  meal.isConsumed ? Icons.check_circle_rounded : Icons.restaurant_rounded,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealName,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${meal.estimatedCalories} kcal • ${meal.plannedHour ?? '--:--'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: meal.isConsumed,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...meal.foods.map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- ${food.name}${food.quantity != null ? ' (${food.quantity})' : ''}',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _tag('Proteines ${meal.totalProtein}g'),
              _tag('Glucides ${meal.totalCarbs}g'),
              _tag('Lipides ${meal.totalFat}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
