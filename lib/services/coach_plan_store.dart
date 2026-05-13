import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_plan_item.dart';
import '../models/workout_plan_item.dart';

class DashboardCoachStats {
  const DashboardCoachStats({
    required this.totalWorkoutItems,
    required this.completedWorkoutItems,
    required this.totalMeals,
    required this.consumedMeals,
    required this.caloriesConsumed,
    required this.proteins,
    required this.carbs,
    required this.fat,
  });

  final int totalWorkoutItems;
  final int completedWorkoutItems;
  final int totalMeals;
  final int consumedMeals;
  final int caloriesConsumed;
  final int proteins;
  final int carbs;
  final int fat;

  int get remainingWorkoutItems => totalWorkoutItems - completedWorkoutItems;
  int get completionRate => totalWorkoutItems == 0 ? 0 : ((completedWorkoutItems / totalWorkoutItems) * 100).round();
}

class CoachPlanStore {
  static const _workoutKey = 'coach.workout.items';
  static const _mealKey = 'coach.meal.items';

  Future<List<WorkoutPlanItem>> loadWorkoutItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workoutKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((e) => WorkoutPlanItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveWorkoutItems(List<WorkoutPlanItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_workoutKey, raw);
  }

  Future<List<MealPlanItem>> loadMealItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((e) => MealPlanItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveMealItems(List<MealPlanItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_mealKey, raw);
  }

  Future<void> markWorkoutDone(String id, {required bool done}) async {
    final items = await loadWorkoutItems();
    final updated = items.map((item) {
      if (item.id != id) return item;
      return item.copyWith(
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );
    }).toList();
    await saveWorkoutItems(updated);
  }

  Future<void> markMealConsumed(String id, {required bool consumed}) async {
    final items = await loadMealItems();
    final updated = items.map((item) {
      if (item.id != id) return item;
      return item.copyWith(
        isConsumed: consumed,
        consumedAt: consumed ? DateTime.now() : null,
      );
    }).toList();
    await saveMealItems(updated);
  }

  Future<void> appendWorkoutItems(List<WorkoutPlanItem> newItems) async {
    final current = await loadWorkoutItems();
    await saveWorkoutItems([...current, ...newItems]);
  }

  Future<void> appendMealItems(List<MealPlanItem> newItems) async {
    final current = await loadMealItems();
    await saveMealItems([...current, ...newItems]);
  }

  Future<DashboardCoachStats> loadDashboardStats() async {
    final workouts = await loadWorkoutItems();
    final meals = await loadMealItems();
    final consumedMeals = meals.where((e) => e.isConsumed).toList();

    final proteins = consumedMeals.fold<int>(0, (sum, item) => sum + item.totalProtein);
    final carbs = consumedMeals.fold<int>(0, (sum, item) => sum + item.totalCarbs);
    final fat = consumedMeals.fold<int>(0, (sum, item) => sum + item.totalFat);

    return DashboardCoachStats(
      totalWorkoutItems: workouts.length,
      completedWorkoutItems: workouts.where((e) => e.isCompleted).length,
      totalMeals: meals.length,
      consumedMeals: consumedMeals.length,
      caloriesConsumed: consumedMeals.fold<int>(0, (sum, item) => sum + item.estimatedCalories),
      proteins: proteins,
      carbs: carbs,
      fat: fat,
    );
  }
}
