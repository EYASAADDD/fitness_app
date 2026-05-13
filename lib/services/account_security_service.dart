Qimport 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/user_profile_store.dart';
import '../models/security_settings.dart';
import 'journal_service.dart';
import 'local_notification_service.dart';
import 'reminder_service.dart';

class AccountSecurityService {
  static const _securityKey = 'account.security.settings';

  final JournalService _journalService = JournalService();
  final ReminderService _reminderService = ReminderService();

  Future<SecuritySettings> loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_securityKey);
    if (raw == null || raw.isEmpty) {
      return const SecuritySettings(
        appLockEnabled: false,
        biometricEnabled: false,
      );
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SecuritySettings.fromMap(map);
    } catch (_) {
      return const SecuritySettings(
        appLockEnabled: false,
        biometricEnabled: false,
      );
    }
  }

  Future<void> saveSecuritySettings(SecuritySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityKey, jsonEncode(settings.toMap()));
  }

  Future<void> logoutLocal() async {
    await UserProfileStore.clear();
  }

  Future<void> clearAllLocalData() async {
    await UserProfileStore.clear();
    await _journalService.clear();
    await _reminderService.clear();
    await LocalNotificationService.instance.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_securityKey);
  }
}
