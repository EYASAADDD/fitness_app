import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 2;
  String _resultTitle = 'Ready to analyze';
  String _resultText = 'Choose a module and import an image, screenshot or PDF page.';
  List<String> _resultTags = const ['OCR', 'Pose', 'Face'];

  static const List<_AnalyzerPreset> _workoutPresets = [
    _AnalyzerPreset(
      title: 'Squat Program',
      subtitle: '4x12 squats, 45s rest',
      result: 'Warm-up 5 min\nSquat 4x12\nLunge 3x10\nPlank 3x45s',
      tags: ['Series', 'Reps', 'Rest'],
    ),
    _AnalyzerPreset(
      title: 'Upper Body Split',
      subtitle: 'Chest, back and shoulders',
      result: 'Bench press 4x10\nRow 4x12\nShoulder press 3x10\nPush-up 3x15',
      tags: ['Strength', 'Hypertrophy'],
    ),
  ];

  static const List<_AnalyzerPreset> _nutritionPresets = [
    _AnalyzerPreset(
      title: 'Meal Plan OCR',
      subtitle: 'Breakfast / lunch / dinner',
      result: 'Breakfast: 2 eggs, banana, milk\nLunch: rice 200g, chicken breast\nDinner: salmon, vegetables',
      tags: ['Calories', 'Macros'],
    ),
    _AnalyzerPreset(
      title: 'Nutrition Table',
      subtitle: 'Calories, protein, carbs, fat',
      result: 'Calories 1840\nProtein 140g\nCarbs 160g\nFat 58g',
      tags: ['Calories', 'Protein'],
    ),
  ];

  static const List<_AnalyzerPreset> _livePresets = [
    _AnalyzerPreset(
      title: 'Pose Detection',
      subtitle: 'Squat posture check',
      result: 'Body centered\nKnee angle 92°\nBack angle stable\nRepetition counter ready',
      tags: ['Pose', 'Angles'],
    ),
    _AnalyzerPreset(
      title: 'Face Monitoring',
      subtitle: 'Cadrage and head direction',
      result: 'Face detected\nHead orientation centered\nCadrage valid\nKeep the head straight',
      tags: ['Face', 'Focus'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (route) => false,
      );
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.recipesScreen);
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.searchScreen);
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.statisticsScreen);
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
      return;
    }
    setState(() => _navIndex = index);
  }

  void _applyPreset(_AnalyzerPreset preset) {
    setState(() {
      _resultTitle = preset.title;
      _resultText = preset.result;
      _resultTags = preset.tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildWorkoutTab(),
                  _buildNutritionTab(),
                  _buildLiveTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Import Center',
                  style: GoogleFonts.manrope(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Workout OCR, nutrition OCR and live analyzer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.primaryBlue.withAlpha(70)),
            ),
            child: Text(
              'iOS-like',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Workout OCR'),
            Tab(text: 'Nutrition OCR'),
            Tab(text: 'Live Analyzer'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTab() {
    return _buildModuleTab(
      title: 'Import a workout program',
      description: 'Scan a gym routine, Instagram screenshot or PDF page and transform it into a structured plan.',
      accent: AppTheme.primaryBlue,
      presets: _workoutPresets,
      actionLabel: 'Start workout OCR',
      onAction: () => Navigator.pushNamed(context, AppRoutes.workoutImportScreen),
    );
  }

  Widget _buildNutritionTab() {
    return _buildModuleTab(
      title: 'Import a nutrition plan',
      description: 'Read meal plans, macro tables and diet screenshots into a daily nutrition tracker.',
      accent: AppTheme.accentBlue,
      presets: _nutritionPresets,
      actionLabel: 'Start nutrition OCR',
      onAction: () => Navigator.pushNamed(context, AppRoutes.nutritionImportScreen),
    );
  }

  Widget _buildLiveTab() {
    return _buildModuleTab(
      title: 'Live body and face analysis',
      description: 'Use pose detection and face detection to correct posture, count reps and keep the user framed.',
      accent: AppTheme.statusOrange,
      presets: _livePresets,
      actionLabel: 'Open live analyzer',
      onAction: () => Navigator.pushNamed(context, AppRoutes.poseAnalyzerScreen),
    );
  }

  Widget _buildModuleTab({
    required String title,
    required String description,
    required Color accent,
    required List<_AnalyzerPreset> presets,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withAlpha(36),
                AppTheme.bgCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _pill('ML Kit ready', accent),
                  const SizedBox(width: 8),
                  _pill('Mobile first', AppTheme.primaryBlue),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Quick presets',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...presets.map(
          (preset) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PresetCard(
              preset: preset,
              onTap: () => _applyPreset(preset),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ResultPanel(
          title: _resultTitle,
          text: _resultText,
          tags: _resultTags,
        ),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AnalyzerPreset {
  const _AnalyzerPreset({
    required this.title,
    required this.subtitle,
    required this.result,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final String result;
  final List<String> tags;
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.onTap});

  final _AnalyzerPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.title,
    required this.text,
    required this.tags,
  });

  final String title;
  final String text;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result preview',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
