import 'package:vibration/vibration.dart';
import 'settings_service.dart';

class VibrationService {
  static Future<void> vibrate({int durationMs = 60}) async {
    final enabled = await SettingsService.isVibrationEnabled();
    if (!enabled) return;
    if (await Vibration.hasVibrator()) {
      try {
        await Vibration.vibrate(duration: durationMs);
      } catch (_) {}
    }
  }
}
