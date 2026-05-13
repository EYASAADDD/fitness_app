import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/workout_plan_item.dart';
import '../../presentation/pose_analyzer_screen.dart';
import '../../routes/app_routes.dart';
import '../../services/coach_plan_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  int _navIndex = 1;
  final _store = CoachPlanStore();
  List<WorkoutPlanItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final loaded = await _store.loadWorkoutItems();
    if (!mounted) return;
    setState(() {
      _items = loaded;
      _loading = false;
    });
  }

  Future<void> _toggleDone(WorkoutPlanItem item) async {
    await _store.markWorkoutDone(item.id, done: !item.isCompleted);
    await _loadItems();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (route) => false);
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

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((e) => e.isCompleted).length;
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.bgPage,
              elevation: 0,
              pinned: true,
              scrolledUnderElevation: 0,
              toolbarHeight: 72,
              titleSpacing: 20,
              title: Text(
                'Workout',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.workoutImportScreen),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withAlpha(22),
                            AppTheme.bgCard,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppTheme.primaryBlue.withAlpha(90)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Programme coach importe',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Progression du jour: $completed/${_items.length} exercices termines.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Workout To-Do',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration,
                        child: Text(
                          'Aucun exercice importe. Va dans Import Workout puis Scanner Programme.',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ..._items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _WorkoutCard(
                                item: item,
                                onToggleDone: () => _toggleDone(item),
                              ),
                            ),
                          ),
                  ],
                ),
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
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.item,
    required this.onToggleDone,
  });

  final WorkoutPlanItem item;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.isCompleted ? Icons.check_circle_rounded : Icons.fitness_center_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.targetMuscles.join(', '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.isCompleted,
                onChanged: (_) => onToggleDone(),
                activeThumbColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag('${item.sets} series x ${item.reps} reps'),
              _tag('Repos: ${item.restSeconds} sec'),
              _tag(item.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PoseAnalyzerScreen(exerciseName: item.name),
                  ),
                );
              },
              child: Text(item.isCompleted ? 'Exercice termine' : 'Commencer l\'exercice'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
