class ReminderSettings {
  const ReminderSettings({
    required this.waterReminderEnabled,
    required this.mealReminderEnabled,
  });

  final bool waterReminderEnabled;
  final bool mealReminderEnabled;

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      waterReminderEnabled: map['waterReminderEnabled'] as bool? ?? true,
      mealReminderEnabled: map['mealReminderEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterReminderEnabled': waterReminderEnabled,
      'mealReminderEnabled': mealReminderEnabled,
    };
  }

  ReminderSettings copyWith({
    bool? waterReminderEnabled,
    bool? mealReminderEnabled,
  }) {
    return ReminderSettings(
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      mealReminderEnabled: mealReminderEnabled ?? this.mealReminderEnabled,
    );
  }
}
