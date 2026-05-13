import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';

/// Service de notifications locales corrigé :
/// - Timezone locale du device (plus UTC fixe)
/// - Meal reminder : répétition quotidienne via matchDateTimeComponents
/// - Water reminder : créneaux fixes sur 7 jours (8h→22h toutes les 2h)
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  static const int _mealId        = 100;
  static const int _waterBaseId   = 200;
  static const int _waterPerDay   = 8;   // 8h, 10h, 12h, 14h, 16h, 18h, 20h, 22h
  static const int _waterDays     = 7;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Timezone locale du device
    try {
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _details({String channelId = 'reminders_channel'}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, 'Reminders',
        channelDescription: 'Health and fitness reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, presentSound: true,
      ),
    );
  }

  // ── Sync avec les paramètres ───────────────────────────────────────────────
  Future<void> syncWithSettings(ReminderSettings settings) async {
    await initialize();

    if (settings.mealReminderEnabled) {
      await _scheduleMealReminder();
    } else {
      await _plugin.cancel(_mealId);
    }

    if (settings.waterReminderEnabled) {
      await _scheduleWaterReminders();
    } else {
      await _cancelWaterReminders();
    }
  }

  // ── Meal reminder : chaque jour à 13h ─────────────────────────────────────
  Future<void> _scheduleMealReminder() async {
    await _plugin.cancel(_mealId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 13);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _mealId,
      'Meal Reminder 🍽️',
      "It's time for your healthy meal!",
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // répète chaque jour
    );
  }

  // ── Water reminder : toutes les 2h de 8h à 22h sur 7 jours ──────────────
  Future<void> _scheduleWaterReminders() async {
    await _cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);
    int id = _waterBaseId;

    for (int day = 0; day < _waterDays; day++) {
      for (int slot = 0; slot < _waterPerDay; slot++) {
        final hour = 8 + slot * 2; // 8,10,12,14,16,18,20,22
        final scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + day, hour,
        );
        if (scheduled.isBefore(now)) continue;

        await _plugin.zonedSchedule(
          id++,
          'Hydration Reminder 💧',
          'Stay hydrated – drink a glass of water!',
          scheduled,
          _details(channelId: 'water_channel'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> _cancelWaterReminders() async {
    final total = _waterPerDay * _waterDays;
    for (int i = 0; i < total; i++) {
      await _plugin.cancel(_waterBaseId + i);
    }
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
