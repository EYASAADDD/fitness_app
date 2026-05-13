import 'scan_result_model.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.result,
  });

  final String id;
  final DateTime timestamp;
  final ScanResultModel result;

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      result: ScanResultModel.fromMap(
        Map<String, dynamic>.from(map['result'] as Map),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'result': result.toMap(),
    };
  }
}
