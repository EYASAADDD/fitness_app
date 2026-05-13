import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';
import '../models/scan_result_model.dart';

class JournalService {
  static const _journalKey = 'nutrition.journal.entries';

  Future<void> addEntry(ScanResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_journalKey) ?? <String>[];
    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      result: result,
    );

    existing.insert(0, jsonEncode(entry.toMap()));
    await prefs.setStringList(_journalKey, existing.take(200).toList());
  }

  Future<List<JournalEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_journalKey) ?? <String>[];

    return raw
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .map(JournalEntry.fromMap)
        .toList();
  }

  Future<List<JournalEntry>> getTodayEntries() async {
    final all = await getEntries();
    final now = DateTime.now();
    return all.where((entry) {
      final t = entry.timestamp;
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_journalKey);
  }
}
