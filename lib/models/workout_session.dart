/// Represents a recorded workout session with pose and performance metrics
class WorkoutSession {
  final String id;
  final String userId;
  final String exerciseName;
  final int repCount;
  final int setCount;
  final Duration duration;
  final double averagePoseScore;
  final DateTime recordedAt;
  final List<String> feedbackNotes;
  final int caloriesBurned;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.repCount,
    required this.setCount,
    required this.duration,
    required this.averagePoseScore,
    required this.recordedAt,
    this.feedbackNotes = const [],
    this.caloriesBurned = 0,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'exerciseName': exerciseName,
      'repCount': repCount,
      'setCount': setCount,
      'durationSeconds': duration.inSeconds,
      'averagePoseScore': averagePoseScore,
      'recordedAt': recordedAt.toIso8601String(),
      'feedbackNotes': feedbackNotes.join('|'),
      'caloriesBurned': caloriesBurned,
    };
  }

  /// Create from JSON
  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      exerciseName: json['exerciseName'] as String,
      repCount: json['repCount'] as int,
      setCount: json['setCount'] as int,
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      averagePoseScore: (json['averagePoseScore'] as num?)?.toDouble() ?? 0.0,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      feedbackNotes: (json['feedbackNotes'] as String?)?.split('|') ?? [],
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
    );
  }

  /// Create a copy with modified fields
  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? exerciseName,
    int? repCount,
    int? setCount,
    Duration? duration,
    double? averagePoseScore,
    DateTime? recordedAt,
    List<String>? feedbackNotes,
    int? caloriesBurned,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseName: exerciseName ?? this.exerciseName,
      repCount: repCount ?? this.repCount,
      setCount: setCount ?? this.setCount,
      duration: duration ?? this.duration,
      averagePoseScore: averagePoseScore ?? this.averagePoseScore,
      recordedAt: recordedAt ?? this.recordedAt,
      feedbackNotes: feedbackNotes ?? this.feedbackNotes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}

/// Rep counting state machine
enum RepState {
  down,   // Body in down position (lowered)
  up,     // Body in up position (raised)
  counting, // Actively counting reps
}

/// Tracks rep counting logic for exercises
class RepCounter {
  int count = 0;
  RepState state = RepState.down;
  final List<double> angleHistory = [];

  /// Check if rep should be counted based on joint angles
  bool updateRep(double currentAngle, {double downThreshold = 90, double upThreshold = 150}) {
    angleHistory.add(currentAngle);

    // Keep only last 10 angle samples
    if (angleHistory.length > 10) {
      angleHistory.removeAt(0);
    }

    bool repCounted = false;

    // Simple state machine: DOWN -> UP -> DOWN = 1 rep
    if (state == RepState.down && currentAngle > upThreshold) {
      state = RepState.up;
    } else if (state == RepState.up && currentAngle < downThreshold) {
      state = RepState.down;
      count++;
      repCounted = true;
    }

    return repCounted;
  }

  void reset() {
    count = 0;
    state = RepState.down;
    angleHistory.clear();
  }
}
