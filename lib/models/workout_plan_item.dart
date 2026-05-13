class WorkoutPlanItem {
  const WorkoutPlanItem({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.difficulty,
    required this.targetMuscles,
    this.durationSeconds,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String name;
  final int sets;
  final int reps;
  final int restSeconds;
  final String difficulty;
  final List<String> targetMuscles;
  final int? durationSeconds;
  final bool isCompleted;
  final DateTime? completedAt;

  WorkoutPlanItem copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    int? restSeconds,
    String? difficulty,
    List<String>? targetMuscles,
    int? durationSeconds,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return WorkoutPlanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      difficulty: difficulty ?? this.difficulty,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'difficulty': difficulty,
      'targetMuscles': targetMuscles,
      'durationSeconds': durationSeconds,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory WorkoutPlanItem.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanItem(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as int? ?? 0,
      restSeconds: json['restSeconds'] as int? ?? 45,
      difficulty: json['difficulty'] as String? ?? 'intermediaire',
      targetMuscles: (json['targetMuscles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      durationSeconds: json['durationSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
    );
  }
}
