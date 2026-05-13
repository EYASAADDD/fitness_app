import 'package:shared_preferences/shared_preferences.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.name,
    required this.email,
    required this.bmi,
    required this.bmiStatus,
    required this.diseases,
    required this.avatarUrl,
    required this.age,
    required this.weight,
    required this.height,
    this.goal = 'maintien',
    this.level = 'debutant',
  });

  final String name;
  final String email;
  final double bmi;
  final String bmiStatus;
  final List<String> diseases;
  final String avatarUrl;
  final int age;
  final double weight;
  final double height;
  final String goal;
  final String level;

  static const AppUserProfile defaults = AppUserProfile(
    name: 'Anouk Garreau',
    email: '',
    bmi: 22.5,
    bmiStatus: 'Normal',
    diseases: ['Diabetes', 'Hypertension'],
    avatarUrl: '',
    age: 28,
    weight: 65,
    height: 170,
    goal: 'maintien',
    level: 'debutant',
  );

  AppUserProfile copyWith({
    String? name,
    String? email,
    double? bmi,
    String? bmiStatus,
    List<String>? diseases,
    String? avatarUrl,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? level,
  }) {
    return AppUserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      bmi: bmi ?? this.bmi,
      bmiStatus: bmiStatus ?? this.bmiStatus,
      diseases: diseases ?? this.diseases,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      level: level ?? this.level,
    );
  }

  bool get hasRealProfile => email.trim().isNotEmpty;
}

class UserProfileStore {
  static const _legacyAvatarUrl =
      'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200';

  static const _nameKey = 'user.name';
  static const _emailKey = 'user.email';
  static const _bmiKey = 'user.bmi';
  static const _bmiStatusKey = 'user.bmiStatus';
  static const _diseasesKey = 'user.diseases';
  static const _avatarUrlKey = 'user.avatarUrl';
  static const _ageKey = 'user.age';
  static const _weightKey = 'user.weight';
  static const _heightKey = 'user.height';
  static const _goalKey = 'user.goal';
  static const _levelKey = 'user.level';

  static AppUserProfile? appUserProfile;

  static Future<AppUserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_nameKey) ?? AppUserProfile.defaults.name;
    final email = prefs.getString(_emailKey) ?? '';
    final bmi = prefs.getDouble(_bmiKey) ?? AppUserProfile.defaults.bmi;
    final bmiStatus =
        prefs.getString(_bmiStatusKey) ?? AppUserProfile.defaults.bmiStatus;
    final diseases =
        prefs.getStringList(_diseasesKey) ?? AppUserProfile.defaults.diseases;
    final rawAvatarUrl =
        prefs.getString(_avatarUrlKey) ?? AppUserProfile.defaults.avatarUrl;
    final avatarUrl = rawAvatarUrl == _legacyAvatarUrl ? '' : rawAvatarUrl;
    final age = prefs.getInt(_ageKey) ?? AppUserProfile.defaults.age;
    final weight =
        prefs.getDouble(_weightKey) ?? AppUserProfile.defaults.weight;
    final height =
        prefs.getDouble(_heightKey) ?? AppUserProfile.defaults.height;
    final goal = prefs.getString(_goalKey) ?? AppUserProfile.defaults.goal;
    final level = prefs.getString(_levelKey) ?? AppUserProfile.defaults.level;

    final profile = AppUserProfile(
      name: name,
      email: email,
      bmi: bmi,
      bmiStatus: bmiStatus,
      diseases: diseases,
      avatarUrl: avatarUrl,
      age: age,
      weight: weight,
      height: height,
      goal: goal,
      level: level,
    );
    
    appUserProfile = profile;
    return profile;
  }

  static Future<void> save(AppUserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name);
    await prefs.setString(_emailKey, profile.email);
    await prefs.setDouble(_bmiKey, profile.bmi);
    await prefs.setString(_bmiStatusKey, profile.bmiStatus);
    await prefs.setStringList(_diseasesKey, profile.diseases);
    await prefs.setString(_avatarUrlKey, profile.avatarUrl);
    await prefs.setInt(_ageKey, profile.age);
    await prefs.setDouble(_weightKey, profile.weight);
    await prefs.setDouble(_heightKey, profile.height);
    await prefs.setString(_goalKey, profile.goal);
    await prefs.setString(_levelKey, profile.level);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_bmiKey);
    await prefs.remove(_bmiStatusKey);
    await prefs.remove(_diseasesKey);
    await prefs.remove(_avatarUrlKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_heightKey);
    await prefs.remove(_goalKey);
    await prefs.remove(_levelKey);
  }
}
