import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam.dart';

class ExamStore {
  static const _storageKey = 'sualati.examLibrary.v1';

  Future<List<Exam>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Exam.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(List<Exam> exams) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(exams.map((exam) => exam.toJson()).toList()),
    );
  }
}
