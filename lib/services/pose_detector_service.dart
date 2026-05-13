import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/workout_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Résultat d'analyse d'une frame pour un exercice donné
// ─────────────────────────────────────────────────────────────────────────────
class ExerciseFrameResult {
  /// Angle principal de l'exercice (coude, genou, alignement…)
  final double angle;

  /// Feedback textuel à afficher
  final String feedback;

  /// Statut lisible ("Good posture", "Adjust form", …)
  final String status;

  /// Une répétition vient d'être comptée sur cette frame
  final bool repCounted;

  /// Nombre de reps total à cet instant
  final int totalReps;

  /// Confidence de détection (0.0 → 1.0)
  final double confidence;

  const ExerciseFrameResult({
    required this.angle,
    required this.feedback,
    required this.status,
    required this.repCounted,
    required this.totalReps,
    required this.confidence,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Type d'exercice reconnu
// ─────────────────────────────────────────────────────────────────────────────
enum ExerciseType { squat, pushup, plank, unknown }

ExerciseType exerciseTypeFromName(String name) {
  final l = name.toLowerCase();
  if (l.contains('squat')) return ExerciseType.squat;
  if (l.contains('push') || l.contains('pompe') || l.contains('pushup')) {
    return ExerciseType.pushup;
  }
  if (l.contains('plank') || l.contains('gainage')) return ExerciseType.plank;
  return ExerciseType.unknown;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service principal
// ─────────────────────────────────────────────────────────────────────────────
class PoseDetectorService {
  late PoseDetector _poseDetector;

  /// Un RepCounter par exercice (réinitialisé à chaque session)
  final RepCounter repCounter = RepCounter();

  /// Timer interne pour le Plank (secondes tenus)
  int plankSeconds = 0;
  DateTime? _plankStart;

  // ── Initialisation ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  // ── Détection brute ────────────────────────────────────────────────────────
  Future<List<Pose>> detectPose(InputImage image) async {
    try {
      return await _poseDetector.processImage(image);
    } catch (e) {
      debugPrint('Pose detection error: $e');
      return [];
    }
  }

  // ── Point d'entrée principal : analyse une frame pour un exercice ──────────
  /// Retourne un [ExerciseFrameResult] complet.
  /// [exerciseName] est le nom libre venant du WorkoutPlanItem.
  ExerciseFrameResult analyzeFrame(Pose pose, String exerciseName) {
    final type = exerciseTypeFromName(exerciseName);
    final conf = calculatePoseConfidence(pose);

    switch (type) {
      case ExerciseType.squat:
        return _analyzeSquat(pose, conf);
      case ExerciseType.pushup:
        return _analyzePushup(pose, conf);
      case ExerciseType.plank:
        return _analyzePlank(pose, conf);
      case ExerciseType.unknown:
        // Fallback : on utilise push-up (angle coude)
        return _analyzePushup(pose, conf);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. SQUAT  –  hip → knee → ankle
  // ─────────────────────────────────────────────────────────────────────────
  ExerciseFrameResult _analyzeSquat(Pose pose, double conf) {
    final lm = pose.landmarks;

    // Landmarks requis (côté gauche)
    final lHip   = lm[PoseLandmarkType.leftHip];
    final lKnee  = lm[PoseLandmarkType.leftKnee];
    final lAnkle = lm[PoseLandmarkType.leftAnkle];

    if (lHip == null || lKnee == null || lAnkle == null) {
      return _notDetected(repCounter.count, conf);
    }

    final angle = calculateAngle(lHip, lKnee, lAnkle);

    // ── Feedback posture ────────────────────────────────────────────────────
    String feedback;
    String status;

    if (angle > 160) {
      feedback = 'Descendez plus bas';
      status   = 'Position haute';
    } else if (angle >= 70 && angle <= 100) {
      feedback = 'Bonne posture ✓';
      status   = 'Good posture ✓';
    } else if (angle < 60) {
      feedback = 'Trop bas – remontez légèrement';
      status   = 'Adjust form';
    } else if (angle < 90) {
      feedback = 'Gardez le dos droit';
      status   = 'Analyzing…';
    } else {
      feedback = 'Continuez…';
      status   = 'Analyzing…';
    }

    // ── Compteur de reps : haut (>160°) → bas (<90°) → haut = 1 rep ────────
    final repCounted = repCounter.updateRep(
      angle,
      downThreshold: 90,
      upThreshold: 160,
    );

    return ExerciseFrameResult(
      angle: angle,
      feedback: feedback,
      status: status,
      repCounted: repCounted,
      totalReps: repCounter.count,
      confidence: conf,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PUSH-UP  –  shoulder → elbow → wrist
  // ─────────────────────────────────────────────────────────────────────────
  ExerciseFrameResult _analyzePushup(Pose pose, double conf) {
    final lm = pose.landmarks;

    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final rElbow    = lm[PoseLandmarkType.rightElbow];
    final rWrist    = lm[PoseLandmarkType.rightWrist];

    if (rShoulder == null || rElbow == null || rWrist == null) {
      return _notDetected(repCounter.count, conf);
    }

    // Angle : shoulder – elbow – wrist
    final angle = calculateAngle(rShoulder, rElbow, rWrist);

    // ── Feedback posture ────────────────────────────────────────────────────
    String feedback;
    String status;

    if (angle > 160) {
      feedback = 'Bon mouvement – bras tendus ✓';
      status   = 'Good posture ✓';
    } else if (angle < 70) {
      feedback = 'Descendez davantage';
      status   = 'Adjust form';
    } else if (angle >= 70 && angle <= 90) {
      feedback = 'Gardez le corps droit';
      status   = 'Good posture ✓';
    } else {
      feedback = 'Continuez…';
      status   = 'Analyzing…';
    }

    // ── Compteur de reps : haut (>160°) → bas (<90°) → haut = 1 rep ────────
    final repCounted = repCounter.updateRep(
      angle,
      downThreshold: 90,
      upThreshold: 160,
    );

    return ExerciseFrameResult(
      angle: angle,
      feedback: feedback,
      status: status,
      repCounted: repCounted,
      totalReps: repCounter.count,
      confidence: conf,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. PLANK  –  shoulder → hip → ankle  (moyenne gauche + droite)
  // ─────────────────────────────────────────────────────────────────────────
  ExerciseFrameResult _analyzePlank(Pose pose, double conf) {
    final lm = pose.landmarks;

    // Côté gauche
    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final lHip      = lm[PoseLandmarkType.leftHip];
    final lAnkle    = lm[PoseLandmarkType.leftAnkle];

    // Côté droit
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final rHip      = lm[PoseLandmarkType.rightHip];
    final rAnkle    = lm[PoseLandmarkType.rightAnkle];

    // On a besoin d'au moins un côté complet
    double? angleLeft;
    double? angleRight;

    if (lShoulder != null && lHip != null && lAnkle != null) {
      angleLeft = calculateAngle(lShoulder, lHip, lAnkle);
    }
    if (rShoulder != null && rHip != null && rAnkle != null) {
      angleRight = calculateAngle(rShoulder, rHip, rAnkle);
    }

    if (angleLeft == null && angleRight == null) {
      return _notDetected(0, conf); // Plank n'a pas de reps
    }

    // Option C : moyenne des deux côtés disponibles
    final double angle;
    if (angleLeft != null && angleRight != null) {
      angle = (angleLeft + angleRight) / 2;
    } else {
      angle = angleLeft ?? angleRight!;
    }

    // ── Feedback posture ────────────────────────────────────────────────────
    String feedback;
    String status;

    if (angle > 160) {
      feedback = 'Bonne posture – corps aligné ✓';
      status   = 'Good posture ✓';
    } else if (angle >= 140 && angle <= 160) {
      feedback = 'Ne baissez pas les hanches';
      status   = 'Adjust form';
    } else {
      // angle < 140
      feedback = 'Dos penché – redressez-vous';
      status   = 'Adjust form';
    }

    // ── Timer Plank (pas de reps) ───────────────────────────────────────────
    if (angle > 140) {
      // Corps suffisamment aligné → on compte le temps
      _plankStart ??= DateTime.now();
      plankSeconds = DateTime.now().difference(_plankStart!).inSeconds;
    } else {
      // Mauvaise posture → on remet le timer à zéro
      _plankStart = null;
      plankSeconds = 0;
    }

    return ExerciseFrameResult(
      angle: angle,
      feedback: feedback,
      status: status,
      repCounted: false,   // Plank = pas de reps
      totalReps: 0,
      confidence: conf,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Résultat quand les landmarks nécessaires ne sont pas détectés
  ExerciseFrameResult _notDetected(int currentReps, double conf) {
    return ExerciseFrameResult(
      angle: 0,
      feedback: 'Positionnez-vous face à la caméra',
      status: 'Not detected',
      repCounted: false,
      totalReps: currentReps,
      confidence: conf,
    );
  }

  /// Calcule l'angle en degrés entre trois landmarks (b = sommet de l'angle)
  /// Utilise les coordonnées (x, y) normalisées de ML Kit
  double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    final dot = baX * bcX + baY * bcY;
    final magBA = math.sqrt(baX * baX + baY * baY);
    final magBC = math.sqrt(bcX * bcX + bcY * bcY);

    if (magBA == 0 || magBC == 0) return 0;

    final cosAngle = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
    return (math.acos(cosAngle) * 180 / math.pi).roundToDouble();
  }

  /// Confidence réelle : ratio de landmarks détectés sur 33 attendus
  double calculatePoseConfidence(Pose pose) {
    if (pose.landmarks.isEmpty) return 0.0;
    // ML Kit retourne jusqu'à 33 landmarks
    return (pose.landmarks.length / 33).clamp(0.0, 1.0);
  }

  /// Réinitialise le compteur et le timer plank pour une nouvelle session
  void resetSession() {
    repCounter.reset();
    plankSeconds = 0;
    _plankStart = null;
  }

  // ── Méthodes legacy conservées pour compatibilité ──────────────────────────
  /// @deprecated Utiliser analyzeFrame() à la place
  String getPushupFeedback(Pose pose) =>
      _analyzePushup(pose, calculatePoseConfidence(pose)).feedback;

  /// @deprecated Utiliser analyzeFrame() à la place
  String getSquatFeedback(Pose pose) =>
      _analyzeSquat(pose, calculatePoseConfidence(pose)).feedback;

  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
