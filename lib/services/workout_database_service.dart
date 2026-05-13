import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';

/// Service for managing offline workout session storage using SQLite
class WorkoutDatabaseService {
  static Database? _database;
  static const String _dbName = 'smarthealth_workouts.db';
  static const String _tableName = 'workout_sessions';
  static const int _version = 1;

  /// Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    debugPrint('Opening database at: $path');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');
    
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        exerciseName TEXT NOT NULL,
        repCount INTEGER NOT NULL,
        setCount INTEGER NOT NULL,
        durationSeconds INTEGER NOT NULL,
        averagePoseScore REAL NOT NULL,
        recordedAt TEXT NOT NULL,
        feedbackNotes TEXT,
        caloriesBurned INTEGER DEFAULT 0,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    debugPrint('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database upgrade: $oldVersion -> $newVersion');
    // Add future migrations here
  }

  /// Insert a new workout session
  Future<String> insertSession(WorkoutSession session) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        session.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Session inserted: ${session.id}');
      return session.id;
    } catch (e) {
      debugPrint('Error inserting session: $e');
      rethrow;
    }
  }

  /// Get all sessions for a user
  Future<List<WorkoutSession>> getSessionsByUser(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'recordedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return WorkoutSession.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error querying sessions: $e');
      return [];
    }
  }

  /// Get sessions within date range
  Future<List<WorkoutSession>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ? AND recordedAt >= ? AND recordedAt <= ?',
        whereArgs: [
          userId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'recordedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return WorkoutSession.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error querying sessions by date: $e');
      return [];
    }
  }

  /// Get sessions by exercise type
  Future<List<WorkoutSession>> getSessionsByExercise(
    String userId,
    String exerciseName,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ? AND exerciseName = ?',
        whereArgs: [userId, exerciseName],
        orderBy: 'recordedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return WorkoutSession.fromJson(maps[i]);
      });
    } catch (e) {
      debugPrint('Error querying sessions by exercise: $e');
      return [];
    }
  }

  /// Get latest session
  Future<WorkoutSession?> getLatestSession(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'recordedAt DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return WorkoutSession.fromJson(maps.first);
    } catch (e) {
      debugPrint('Error querying latest session: $e');
      return null;
    }
  }

  /// Get total stats for user
  Future<WorkoutStats> getWorkoutStats(String userId) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as totalSessions,
          SUM(repCount) as totalReps,
          SUM(durationSeconds) as totalDurationSeconds,
          AVG(averagePoseScore) as avgPoseScore,
          SUM(caloriesBurned) as totalCalories
        FROM $_tableName
        WHERE userId = ?
      ''', [userId]);

      if (result.isEmpty) {
        return WorkoutStats.empty();
      }

      final row = result.first;
      return WorkoutStats(
        totalSessions: row['totalSessions'] as int? ?? 0,
        totalReps: row['totalReps'] as int? ?? 0,
        totalDurationSeconds: row['totalDurationSeconds'] as int? ?? 0,
        averagePoseScore: (row['avgPoseScore'] as num?)?.toDouble() ?? 0.0,
        totalCalories: row['totalCalories'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return WorkoutStats.empty();
    }
  }

  /// Update session
  Future<int> updateSession(WorkoutSession session) async {
    try {
      final db = await database;
      return await db.update(
        _tableName,
        session.toJson(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } catch (e) {
      debugPrint('Error updating session: $e');
      rethrow;
    }
  }

  /// Delete session
  Future<int> deleteSession(String sessionId) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  /// Delete all sessions for user
  Future<int> deleteUserSessions(String userId) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error deleting user sessions: $e');
      rethrow;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      debugPrint('All workout sessions cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed');
    }
  }
}

/// Aggregated workout statistics
class WorkoutStats {
  final int totalSessions;
  final int totalReps;
  final int totalDurationSeconds;
  final double averagePoseScore;
  final int totalCalories;

  WorkoutStats({
    required this.totalSessions,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.averagePoseScore,
    required this.totalCalories,
  });

  factory WorkoutStats.empty() {
    return WorkoutStats(
      totalSessions: 0,
      totalReps: 0,
      totalDurationSeconds: 0,
      averagePoseScore: 0.0,
      totalCalories: 0,
    );
  }

  int get totalDurationMinutes => totalDurationSeconds ~/ 60;
  double get averageRepsPerSession => totalSessions > 0 ? totalReps / totalSessions : 0;
}
