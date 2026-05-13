import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  final List<String> _chips = const ['Exercises', 'Meals', 'History', 'Programs'];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Squat',
      'Chicken bowl',
      'Workout history',
      'Upper body program',
      'Hydration reminder',
    ].where((item) => item.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPage,
        elevation: 0,
        title: Text('Search', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TextField(
            controller: _controller,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search exercises, meals, history, programs...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chips.map((chip) => Chip(label: Text(chip))).toList(),
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.manage_search_rounded, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item, style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.historyScreen),
            child: const Text('Open history'),
          ),
        ],
      ),
    );
  }
}
