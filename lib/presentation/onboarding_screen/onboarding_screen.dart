import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/user_profile_store.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final _pages = const [
    _OnboardingPageData(
      title: 'Importez vos programmes automatiquement',
      description: 'OCR intelligent pour transformer des captures, PDF et photos en workout cards.',
      icon: Icons.document_scanner_rounded,
      accent: AppTheme.primaryBlue,
    ),
    _OnboardingPageData(
      title: 'Analysez votre posture en temps réel',
      description: 'Pose detection, angle genou et feedback live pour vos répétitions.',
      icon: Icons.accessibility_new_rounded,
      accent: AppTheme.accentBlue,
    ),
    _OnboardingPageData(
      title: 'Suivez votre nutrition et progression',
      description: 'Meal cards, calories, history, favoris et statistiques dans une seule app.',
      icon: Icons.restaurant_rounded,
      accent: AppTheme.statusOrange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    await UserProfileStore.save(
      AppUserProfile.defaults.copyWith(email: 'guest@smartcoach.app'),
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (route) => false);
  }

  void _skip() => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.authScreen, (route) => false);

  void _next() {
    if (_pageIndex < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _startApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Smart AI Fitness Coach', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: _skip, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemCount: _pages.length,
                  itemBuilder: (_, index) => _buildPage(_pages[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _pageIndex == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _pageIndex == index ? AppTheme.primaryBlue : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_pageIndex == _pages.length - 1 ? 'Start app' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: page.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: page.accent.withAlpha(70)),
            ),
            child: Icon(page.icon, size: 54, color: page.accent),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({required this.title, required this.description, required this.icon, required this.accent});

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
