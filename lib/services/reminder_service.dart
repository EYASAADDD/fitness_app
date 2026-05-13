import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import 'local_notification_service.dart';

class ReminderService {
  static const _key = 'app.reminders.settings';

  Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const ReminderSettings(
        waterReminderEnabled: true,
        mealReminderEnabled: false,
      );
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReminderSettings.fromMap(map);
    } catch (_) {
      return const ReminderSettings(
        waterReminderEnabled: true,
        mealReminderEnabled: false,
      );
    }
  }

  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toMap()));
    await LocalNotificationService.instance.syncWithSettings(settings);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
