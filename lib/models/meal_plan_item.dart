class MealFoodItem {
  const MealFoodItem({
    required this.name,
    this.quantity,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final String name;
  final String? quantity;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory MealFoodItem.fromJson(Map<String, dynamic> json) {
    return MealFoodItem(
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
    );
  }
}

class MealPlanItem {
  const MealPlanItem({
    required this.id,
    required this.mealName,
    required this.foods,
    required this.estimatedCalories,
    this.plannedHour,
    this.isConsumed = false,
    this.consumedAt,
  });

  final String id;
  final String mealName;
  final List<MealFoodItem> foods;
  final int estimatedCalories;
  final String? plannedHour;
  final bool isConsumed;
  final DateTime? consumedAt;

  int get totalProtein => foods.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => foods.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => foods.fold(0, (sum, item) => sum + item.fat);

  MealPlanItem copyWith({
    String? id,
    String? mealName,
    List<MealFoodItem>? foods,
    int? estimatedCalories,
    String? plannedHour,
    bool? isConsumed,
    DateTime? consumedAt,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      mealName: mealName ?? this.mealName,
      foods: foods ?? this.foods,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      plannedHour: plannedHour ?? this.plannedHour,
      isConsumed: isConsumed ?? this.isConsumed,
      consumedAt: consumedAt ?? this.consumedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealName': mealName,
      'foods': foods.map((e) => e.toJson()).toList(),
      'estimatedCalories': estimatedCalories,
      'plannedHour': plannedHour,
      'isConsumed': isConsumed,
      'consumedAt': consumedAt?.toIso8601String(),
    };
  }

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'] as String,
      mealName: json['mealName'] as String,
      foods: (json['foods'] as List?)
              ?.whereType<Map>()
              .map((e) => MealFoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      estimatedCalories: json['estimatedCalories'] as int? ?? 0,
      plannedHour: json['plannedHour'] as String?,
      isConsumed: json['isConsumed'] as bool? ?? false,
      consumedAt: json['consumedAt'] != null ? DateTime.tryParse(json['consumedAt'].toString()) : null,
    );
  }
}
