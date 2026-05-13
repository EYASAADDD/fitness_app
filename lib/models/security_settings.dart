class SecuritySettings {
  const SecuritySettings({
    required this.appLockEnabled,
    required this.biometricEnabled,
  });

  final bool appLockEnabled;
  final bool biometricEnabled;

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      appLockEnabled: map['appLockEnabled'] as bool? ?? false,
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appLockEnabled': appLockEnabled,
      'biometricEnabled': biometricEnabled,
    };
  }

  SecuritySettings copyWith({bool? appLockEnabled, bool? biometricEnabled}) {
    return SecuritySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
