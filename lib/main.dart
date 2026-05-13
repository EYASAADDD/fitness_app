import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/local_notification_service.dart';
import 'services/reminder_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifications
  await LocalNotificationService.instance.initialize();
  final reminderSettings = await ReminderService().load();
  await LocalNotificationService.instance.syncWithSettings(reminderSettings);

  // Theme
  await SettingsService.load();

  // Custom error widget
  bool _hasShownError = false;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () => _hasShownError = false);
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  runApp(const SmartFitnessApp());
}

class SmartFitnessApp extends StatelessWidget {
  const SmartFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Smart AI Fitness Coach',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
          builder: (context, child) {
            // Prevent system font scaling from breaking layout
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
