import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../models/workout_plan_item.dart';
import '../../routes/app_routes.dart';
import '../../services/coach_plan_store.dart';
import '../../services/ocr_workout_import_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/workout_card.dart';
import '../../widgets/empty_state_widget.dart';

/// Workout tab – liste des exercices + OCR scan (caméra directe)
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _store = CoachPlanStore();
  final _ocrService = OCRWorkoutImportService();
  List<WorkoutPlanItem> _items = [];
  bool _loading = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
    _loadItems();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await _store.loadWorkoutItems();
    if (!mounted) return;
    setState(() {
      // Newest first : on inverse la liste stockée
      _items = items.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _toggleDone(WorkoutPlanItem item) async {
    await _store.markWorkoutDone(item.id, done: !item.isCompleted);
    await _loadItems();
  }

  Future<void> _deleteItem(WorkoutPlanItem item) async {
    final items = await _store.loadWorkoutItems();
    final updated = items.where((e) => e.id != item.id).toList();
    await _store.saveWorkoutItems(updated);
    await _loadItems();
  }

  /// Auto-check depuis PoseAnalyzer : appelé quand confidence == 100%
  Future<void> autoCheckWorkout(String workoutName) async {
    final items = await _store.loadWorkoutItems();
    final target = items.where(
      (e) => e.name.toLowerCase() == workoutName.toLowerCase() && !e.isCompleted,
    );
    if (target.isEmpty) return;
    await _store.markWorkoutDone(target.first.id, done: true);
    await _loadItems();
  }

  /// Scan Workout → CAMÉRA directe (fromCamera: true)
  Future<void> _scanWorkout() async {
    setState(() => _scanning = true);
    try {
      final picked = await _ocrService.pickImage(fromCamera: true); // ← caméra
      if (picked == null) return;

      final result = await _ocrService.extractWorkoutFromImage(picked.path);

      if (result.exercises.isEmpty) {
        if (!mounted) return;
        _showSnack('No exercises detected. Try a clearer image.', isError: true);
        return;
      }

      final newItems = result.exercises.map((e) {
        return WorkoutPlanItem(
          id: const Uuid().v4(),
          name: e.name,
          sets: e.sets ?? 3,
          reps: e.reps ?? 12,
          restSeconds: 45,
          difficulty: (result.difficulty ?? 'intermediate').toLowerCase(),
          targetMuscles: _guessMuscles(e.name),
          durationSeconds: e.durationSeconds,
        );
      }).toList();

      // Prepend : nouveaux items en tête de liste dans le store
      final existing = await _store.loadWorkoutItems();
      await _store.saveWorkoutItems([...newItems, ...existing]);
      await _loadItems();

      if (!mounted) return;
      _showSnack('${newItems.length} exercise(s) added ✓');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addManually() async {
    final result = await showDialog<WorkoutPlanItem>(
      context: context,
      builder: (_) => const _AddExerciseDialog(),
    );
    if (result != null) {
      // Prepend : nouvel item en tête
      final existing = await _store.loadWorkoutItems();
      await _store.saveWorkoutItems([result, ...existing]);
      await _loadItems();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Clear all?', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
        content: Text(
          'This will delete all workout exercises.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.statusRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _store.saveWorkoutItems([]);
      await _loadItems();
    }
  }

  List<String> _guessMuscles(String name) {
    final l = name.toLowerCase();
    if (l.contains('squat') || l.contains('lunge')) return ['Quadriceps', 'Glutes'];
    if (l.contains('push') || l.contains('press')) return ['Chest', 'Triceps'];
    if (l.contains('pull') || l.contains('row')) return ['Back', 'Biceps'];
    if (l.contains('plank') || l.contains('core') || l.contains('crunch')) return ['Core'];
    if (l.contains('curl')) return ['Biceps'];
    if (l.contains('dip') || l.contains('tricep')) return ['Triceps'];
    if (l.contains('run') || l.contains('jump')) return ['Full body'];
    return ['Full body'];
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.statusRed : AppTheme.fitGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);
    final done = _items.where((e) => e.isCompleted).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Workout',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
          ),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.statusRed),
              tooltip: 'Clear all',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Action bar : Scan + Add (sans icône Live) ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: _scanning ? 'Scanning…' : 'Scan Workout',
                    icon: Icons.document_scanner_rounded,
                    color: AppTheme.fitGreen,
                    onTap: _scanning ? null : _scanWorkout,
                    loading: _scanning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Add Exercise',
                    icon: Icons.add_rounded,
                    color: AppTheme.statusBlue,
                    onTap: _addManually,
                  ),
                ),
                // ← Icône "homme/live" supprimée
              ],
            ),
          ),
          // ── Progress bar ────────────────────────────────────────────────
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _ProgressBar(done: done, total: _items.length, isDark: isDark),
            ),
          // ── Liste (newest first) ────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.fitGreen))
                : _items.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.fitness_center_rounded,
                        title: 'No exercises yet',
                        description: 'Scan a workout image or add exercises manually.',
                        ctaLabel: 'Scan Workout',
                        onCta: _scanWorkout,
                      )
                    : RefreshIndicator(
                        color: AppTheme.fitGreen,
                        onRefresh: _loadItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return WorkoutCard(
                              item: item,
                              onToggleDone: () => _toggleDone(item),
                              onDelete: () => _deleteItem(item),
                              onStart: () => Navigator.pushNamed(
                                context,
                                AppRoutes.poseAnalyzerScreen,
                                arguments: item.name,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final bool isDark;

  const _ProgressBar({required this.done, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / $total completed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : const Color(0xFF111111),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.fitGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.fitGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add exercise dialog ──────────────────────────────────────────────────────

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '12');
  final _restCtrl = TextEditingController(text: '45');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Add Exercise',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameCtrl, 'Exercise name', hint: 'e.g. Push-up'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(_setsCtrl, 'Sets', hint: '3', numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_repsCtrl, 'Reps', hint: '12', numeric: true)),
              ],
            ),
            const SizedBox(height: 10),
            _field(_restCtrl, 'Rest (sec)', hint: '45', numeric: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              WorkoutPlanItem(
                id: const Uuid().v4(),
                name: name,
                sets: int.tryParse(_setsCtrl.text) ?? 3,
                reps: int.tryParse(_repsCtrl.text) ?? 12,
                restSeconds: int.tryParse(_restCtrl.text) ?? 45,
                difficulty: 'intermediate',
                targetMuscles: const [],
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? hint, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
      ),
    );
  }
}
