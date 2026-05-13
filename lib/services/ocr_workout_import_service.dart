import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Result of OCR workout import
class WorkoutImportResult {
  final String rawText;
  final List<ExerciseExtract> exercises;
  final String? difficulty;
  final int? estimatedDuration; // in minutes
  final DateTime importedAt;

  WorkoutImportResult({
    required this.rawText,
    required this.exercises,
    this.difficulty,
    this.estimatedDuration,
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();

  bool get isEmpty => exercises.isEmpty;
  bool get isValid => exercises.isNotEmpty;
}

/// Single exercise extracted from OCR
class ExerciseExtract {
  final String name;
  final int? reps;
  final int? sets;
  final int? durationSeconds;
  final String? notes;

  ExerciseExtract({
    required this.name,
    this.reps,
    this.sets,
    this.durationSeconds,
    this.notes,
  });

  @override
  String toString() {
    final parts = [name];
    if (sets != null) parts.add('$sets x ${reps ?? "?"}');
    if (durationSeconds != null) parts.add('${durationSeconds}s');
    return parts.join(' - ');
  }
}

/// Service for OCR-based workout program import
class OCRWorkoutImportService {
  late TextRecognizer _textRecognizer;
  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize the text recognizer
  Future<void> initialize() async {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Pick image from camera or gallery
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  /// Extract workout program from image using OCR
  Future<WorkoutImportResult> extractWorkoutFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final result = _parseWorkoutText(recognizedText.text);
      return result;
    } catch (e) {
      debugPrint('OCR extraction error: $e');
      return WorkoutImportResult(
        rawText: 'Error: $e',
        exercises: [],
      );
    }
  }

  /// Parse raw OCR text to extract exercises
  WorkoutImportResult _parseWorkoutText(String rawText) {
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final exercises = <ExerciseExtract>[];

    for (final line in lines) {
      final exercise = _parseExerciseLine(line);
      if (exercise != null) {
        exercises.add(exercise);
      }
    }

    // Guess difficulty from keywords
    final difficulty = _guessDifficulty(rawText);
    final duration = _estimateDuration(exercises);

    return WorkoutImportResult(
      rawText: rawText,
      exercises: exercises,
      difficulty: difficulty,
      estimatedDuration: duration,
    );
  }

  /// Parse single line to extract exercise details
  /// Handles formats like: "Push-ups 20x3", "Squats 15 reps 4 sets", "Plank 60s"
  ExerciseExtract? _parseExerciseLine(String line) {
    line = line.trim();
    if (line.isEmpty) return null;

    // Look for exercise name and numbers
    final parts = line.split(RegExp(r'[\s-]+'));
    if (parts.isEmpty) return null;

    String name = '';
    int? reps;
    int? sets;
    int? duration;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // Check for reps (e.g., "20x3", "20x", "20")
      if (part.contains(RegExp(r'^\d+x\d+$'))) {
        final parsed = part.split('x');
        reps = int.tryParse(parsed[0]);
        sets = int.tryParse(parsed[1]);
        continue;
      }

      // Check for single number with "reps"
      if (i + 1 < parts.length && 
          (parts[i + 1].toLowerCase().startsWith('rep') || 
           parts[i + 1].toLowerCase().startsWith('x'))) {
        reps = int.tryParse(part);
        if (parts[i + 1].toLowerCase().startsWith('x') && i + 2 < parts.length) {
          sets = int.tryParse(parts[i + 2]);
        }
        continue;
      }

      // Check for sets (e.g., "4 sets")
      if (i + 1 < parts.length && parts[i + 1].toLowerCase().startsWith('set')) {
        sets = int.tryParse(part);
        continue;
      }

      // Check for duration (e.g., "60s", "60 seconds", "1 min")
      if (part.contains(RegExp(r'^\d+s$')) || part.contains(RegExp(r'^\d+m$'))) {
        if (part.endsWith('s')) {
          duration = int.tryParse(part.replaceAll('s', ''));
        } else if (part.endsWith('m')) {
          final minuteValue = int.tryParse(part.replaceAll('m', '')) ?? 0;
          if (minuteValue > 0) {
            duration = minuteValue * 60;
          }
        }
        continue;
      }

      // Accumulate name
      if (name.isEmpty) {
        name = part;
      } else {
        name = '$name $part';
      }
    }

    // Capitalize name
    name = name.replaceAll(RegExp(r'(\d+)'), '').trim();
    if (name.isEmpty) name = 'Exercise';

    return ExerciseExtract(
      name: _capitalizeExerciseName(name),
      reps: reps,
      sets: sets,
      durationSeconds: duration,
    );
  }

  /// Clean and capitalize exercise name
  String _capitalizeExerciseName(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
  }

  /// Guess difficulty from keywords
  String _guessDifficulty(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains(RegExp(r'\b(beginner|easy|simple)\b'))) {
      return 'Beginner';
    } else if (lower.contains(RegExp(r'\b(advanced|expert|hard|difficult)\b'))) {
      return 'Advanced';
    } else if (lower.contains(RegExp(r'\b(intermediate|medium)\b'))) {
      return 'Intermediate';
    }
    
    return 'Unknown';
  }

  /// Estimate total workout duration in minutes
  int _estimateDuration(List<ExerciseExtract> exercises) {
    int totalSeconds = 0;
    
    for (final exercise in exercises) {
      if (exercise.durationSeconds != null) {
        totalSeconds += exercise.durationSeconds!;
      } else if (exercise.reps != null && exercise.sets != null) {
        // Rough estimate: 3 seconds per rep
        totalSeconds += (exercise.reps! * exercise.sets! * 3) + 30; // +30 for rest
      }
    }
    
    return (totalSeconds / 60).ceil();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
