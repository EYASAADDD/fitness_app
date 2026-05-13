import 'package:flutter/material.dart';

import '../home_screen/home_screen.dart';
import '../workout_screen/workout_screen.dart';
import '../nutrition_screen/nutrition_screen.dart';
import '../settings_screen/settings_screen.dart';
import '../../widgets/app_navigation.dart';

/// Main shell that hosts the 4 bottom-nav tabs.
/// Keeps each tab alive using IndexedStack.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _pages = [
    HomeScreen(),
    WorkoutScreen(),
    NutritionScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
