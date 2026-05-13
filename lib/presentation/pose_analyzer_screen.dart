import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';

import '../core/user_profile_store.dart';
import '../models/workout_session.dart';
import '../services/coach_plan_store.dart';
import '../services/pose_detector_service.dart';
import '../services/workout_database_service.dart';
import '../theme/app_theme.dart';

/// Live pose analyzer – détection ML Kit réelle pour Squat, Push-up, Plank.
/// Auto-check workout à 100% de confidence.
class PoseAnalyzerScreen extends StatefulWidget {
  final String? exerciseName;
  const PoseAnalyzerScreen({super.key, this.exerciseName});

  @override
  State<PoseAnalyzerScreen> createState() => _PoseAnalyzerScreenState();
}

class _PoseAnalyzerScreenState extends State<PoseAnalyzerScreen> {
  // ── Services ───────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  late PoseDetectorService _poseService;
  late WorkoutDatabaseService _dbService;
  final _store = CoachPlanStore();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _cameraReady = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _autoChecked = false;

  // ── Métriques temps réel ───────────────────────────────────────────────────
  int    _repsCount   = 0;
  double _confidence  = 0.0;
  double _angle       = 0.0;
  String _feedback    = 'Positionnez-vous face à la caméra';
  String _status      = 'En attente…';

  // ── Timer session ──────────────────────────────────────────────────────────
  Duration  _elapsed   = Duration.zero;
  Timer?    _timer;
  DateTime? _startTime;

  // ── Type d'exercice détecté ────────────────────────────────────────────────
  late ExerciseType _exerciseType;

  @override
  void initState() {
    super.initState();
    _exerciseType = exerciseTypeFromName(widget.exerciseName ?? '');
    _poseService  = PoseDetectorService();
    _dbService    = WorkoutDatabaseService();
    _initAll();
  }

  Future<void> _initAll() async {
    await _poseService.initialize();
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraReady = true);
      await _cameraController!.startImageStream(_onCameraImage);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  // ── Traitement de chaque frame ─────────────────────────────────────────────
  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final poses = await _poseService.detectPose(inputImage);
      if (!mounted) return;

      if (poses.isEmpty) {
        setState(() {
          _confidence = 0.0;
          _feedback   = 'Aucune pose détectée – rapprochez-vous';
          _status     = 'Not detected';
        });
        return;
      }

      // ── Analyse métier via le service ──────────────────────────────────────
      final result = _poseService.analyzeFrame(
        poses.first,
        widget.exerciseName ?? '',
      );

      // Vibration si une rep vient d'être comptée
      if (result.repCounted && _isRecording) {
        HapticFeedback.mediumImpact();
      }

      setState(() {
        _confidence = result.confidence;
        _feedback   = result.feedback;
        _status     = result.status;
        _angle      = result.angle;
        if (_isRecording) {
          _repsCount = _exerciseType == ExerciseType.plank
              ? _poseService.plankSeconds
              : result.totalReps;
        }
      });

      // ── Auto-check à 100% de confidence ───────────────────────────────────
      if (result.confidence >= 1.0 && !_autoChecked && widget.exerciseName != null) {
        _autoChecked = true;
        await _autoCheckWorkout();
      }
    } finally {
      _isProcessing = false;
    }
  }

  // ── Construire InputImage depuis CameraImage ───────────────────────────────
  InputImage? _buildInputImage(CameraImage image) {
    try {
      final camera   = _cameraController!.description;
      final rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Auto-check workout dans CoachPlanStore ─────────────────────────────────
  Future<void> _autoCheckWorkout() async {
    final items = await _store.loadWorkoutItems();
    final target = items.where(
      (e) =>
          e.name.toLowerCase() == (widget.exerciseName ?? '').toLowerCase() &&
          !e.isCompleted,
    );
    if (target.isEmpty) return;
    await _store.markWorkoutDone(target.first.id, done: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.exerciseName} auto-complété à 100% de confidence ✓',
          ),
          backgroundColor: AppTheme.fitGreen,
        ),
      );
    }
  }

  // ── Contrôles session ──────────────────────────────────────────────────────
  void _startRecording() {
    HapticFeedback.mediumImpact();
    _startTime = DateTime.now();
    _poseService.resetSession();
    _autoChecked = false;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startTime!));
      }
    });

    setState(() {
      _isRecording = true;
      _repsCount   = 0;
      _confidence  = 0.0;
      _feedback    = 'Commencez votre exercice !';
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() => _isRecording = false);

    final hasActivity = _exerciseType == ExerciseType.plank
        ? _poseService.plankSeconds > 0
        : _repsCount > 0;

    if (hasActivity) await _saveSession();
  }

  Future<void> _saveSession() async {
    try {
      final profile = UserProfileStore.appUserProfile;
      final userId  = profile?.email ?? 'anonymous';

      final session = WorkoutSession(
        id: const Uuid().v4(),
        userId: userId,
        exerciseName: widget.exerciseName ?? 'Unknown',
        repCount: _exerciseType == ExerciseType.plank
            ? _poseService.plankSeconds // on stocke les secondes comme "reps"
            : _repsCount,
        setCount: 1,
        duration: _elapsed,
        averagePoseScore: _confidence,
        recordedAt: DateTime.now(),
        caloriesBurned: _repsCount * 5,
        feedbackNotes: [_feedback],
      );

      await _dbService.insertSession(session);

      if (mounted) {
        final label = _exerciseType == ExerciseType.plank
            ? '${_poseService.plankSeconds}s tenus'
            : '$_repsCount reps';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session sauvegardée : $label en ${_elapsed.inSeconds}s ✓'),
            backgroundColor: AppTheme.fitGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save session error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPlank = _exerciseType == ExerciseType.plank;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exerciseName ?? 'Pose Analyzer',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          // Badge type d'exercice
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _exerciseColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _exerciseColor.withAlpha(120)),
            ),
            child: Text(
              _exerciseLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _exerciseColor,
              ),
            ),
          ),
        ],
      ),
      body: !_cameraReady
          ? const Center(child: CircularProgressIndicator(color: AppTheme.fitGreen))
          : Stack(
              children: [
                // ── Flux caméra ────────────────────────────────────────────
                Positioned.fill(child: CameraPreview(_cameraController!)),

                // ── Stats overlay haut ─────────────────────────────────────
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Reps ou Timer selon l'exercice
                      _StatBadge(
                        label: isPlank ? 'Temps' : 'Reps',
                        value: isPlank
                            ? '${_poseService.plankSeconds}s'
                            : '$_repsCount',
                        color: AppTheme.fitGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'Confidence',
                        value: '${(_confidence * 100).toStringAsFixed(0)}%',
                        color: _confidenceColor(_confidence),
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'Angle',
                        value: '${_angle.toStringAsFixed(0)}°',
                        color: AppTheme.statusBlue,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'Durée',
                        value:
                            '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),

                // ── Panel bas ──────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(210),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Statut posture ───────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _statusColor(_status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _status,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(_status),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── Feedback message ─────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _feedback,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Barre de confidence ──────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pose Confidence',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white60),
                            ),
                            Text(
                              '${(_confidence * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _confidenceColor(_confidence),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _confidence,
                            minHeight: 5,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(
                                _confidenceColor(_confidence)),
                          ),
                        ),

                        // ── Angle indicator (Plank uniquement) ───────────
                        if (isPlank) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Alignement corps',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.white60),
                              ),
                              Text(
                                '${_angle.toStringAsFixed(0)}° ${_angle > 160 ? "✓" : _angle >= 140 ? "~" : "✗"}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _angle > 160
                                      ? AppTheme.fitGreen
                                      : _angle >= 140
                                          ? AppTheme.statusOrange
                                          : AppTheme.statusRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_angle / 180).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(
                                _angle > 160
                                    ? AppTheme.fitGreen
                                    : _angle >= 140
                                        ? AppTheme.statusOrange
                                        : AppTheme.statusRed,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Bouton Start / Stop ──────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            icon: Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.fiber_manual_record_rounded,
                              size: 22,
                            ),
                            label: Text(
                              _isRecording ? 'Stop & Sauvegarder' : 'Démarrer la session',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? AppTheme.statusRed
                                  : AppTheme.fitGreen,
                              foregroundColor:
                                  _isRecording ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  String get _exerciseLabel {
    switch (_exerciseType) {
      case ExerciseType.squat:   return 'SQUAT';
      case ExerciseType.pushup:  return 'PUSH-UP';
      case ExerciseType.plank:   return 'PLANK';
      case ExerciseType.unknown: return 'EXERCICE';
    }
  }

  Color get _exerciseColor {
    switch (_exerciseType) {
      case ExerciseType.squat:   return AppTheme.fitGreen;
      case ExerciseType.pushup:  return AppTheme.statusBlue;
      case ExerciseType.plank:   return AppTheme.statusOrange;
      case ExerciseType.unknown: return AppTheme.textHint;
    }
  }

  Color _confidenceColor(double conf) {
    if (conf >= 0.8) return AppTheme.fitGreen;
    if (conf >= 0.5) return AppTheme.statusOrange;
    return AppTheme.statusRed;
  }

  Color _statusColor(String status) {
    if (status.contains('Good')) return AppTheme.fitGreen;
    if (status.contains('Adjust') || status.contains('Position')) {
      return AppTheme.statusOrange;
    }
    if (status.contains('Not')) return AppTheme.statusRed;
    return Colors.white60;
  }
}

// ── Sub-widget : badge stat overlay ──────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
