import 'package:flutter/material.dart';

import '../presentation/auth_screen/auth_screen.dart';
import '../presentation/edit_profile_screen/edit_profile_screen.dart';
import '../presentation/history_screen/history_screen.dart';
import '../presentation/main_shell/main_shell.dart';
import '../presentation/nutrition_import_screen/nutrition_import_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/pose_analyzer_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/workout_import_screen/workout_import_screen.dart';
// Legacy screens kept for backward compat (referenced by existing screens)
import '../presentation/recipes_screen/recipes_screen.dart';
import '../presentation/search_screen/search_screen.dart';
import '../presentation/statistics_screen/statistics_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/chatbot_screen/chatbot_screen.dart';
import '../presentation/global_search_screen/global_search_screen.dart';
import '../presentation/scan_screen/scan_screen.dart';

class AppRoutes {
  // ── Route names ────────────────────────────────────────────────────────────
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String authScreen = '/auth-screen';
  static const String homeScreen = '/home-screen';
  static const String workoutImportScreen = '/workout-import-screen';
  static const String nutritionImportScreen = '/nutrition-import-screen';
  static const String poseAnalyzerScreen = '/pose-analyzer-screen';
  static const String onboardingScreen = '/onboarding-screen';
  static const String historyScreen = '/history-screen';
  static const String profileScreen = '/profile-screen';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String settingsScreen = '/settings-screen';
  // Legacy routes (kept for backward compat)
  static const String recipesScreen = '/recipes-screen';
  static const String searchScreen = '/search-screen';
  static const String statisticsScreen = '/statistics-screen';
  static const String favoritesScreen = '/favorites-screen';
  static const String chatbotScreen = '/chatbot-screen';
  static const String globalSearchScreen = '/global-search-screen';
  static const String scanScreen = '/scan-screen';

  // ── Route map ──────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        initial: (_) => const SplashScreen(),
        splashScreen: (_) => const SplashScreen(),
        authScreen: (_) => const AuthScreen(),
        homeScreen: (_) => const MainShell(),
        workoutImportScreen: (_) => const WorkoutImportScreen(),
        nutritionImportScreen: (_) => const NutritionImportScreen(),
        poseAnalyzerScreen: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return PoseAnalyzerScreen(
            exerciseName: args is String ? args : null,
          );
        },
        onboardingScreen: (_) => const OnboardingScreen(),
        historyScreen: (_) => const HistoryScreen(),
        profileScreen: (_) => const ProfileScreen(),
        editProfileScreen: (_) => const EditProfileScreen(),
        settingsScreen: (_) => const SettingsScreen(),
        // Legacy routes
        recipesScreen: (_) => const RecipesScreen(),
        searchScreen: (_) => const SearchScreen(),
        statisticsScreen: (_) => const StatisticsScreen(),
        favoritesScreen: (_) => const FavoritesScreen(),
        chatbotScreen: (_) => const ChatbotScreen(),
        globalSearchScreen: (_) => const GlobalSearchScreen(),
        scanScreen: (_) => const ScanScreen(),
      };
}
