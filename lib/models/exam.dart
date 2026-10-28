import 'package:flutter/material.dart';

/// Supported question formats in the exam editor.
enum QuestionType { multipleChoice, trueFalse, written, fillBlank }

extension QuestionTypeLabel on QuestionType {
  String get label => switch (this) {
        QuestionType.multipleChoice => 'اختيار من متعدد',
        QuestionType.trueFalse => 'صح أم خطأ',
        QuestionType.written => 'إجابة تحريرية',
        QuestionType.fillBlank => 'أكمل الفراغ',
      };

  IconData get icon => switch (this) {
        QuestionType.multipleChoice => Icons.radio_button_checked_rounded,
        QuestionType.trueFalse => Icons.check_circle_outline_rounded,
        QuestionType.written => Icons.short_text_rounded,
        QuestionType.fillBlank => Icons.edit_note_rounded,
      };
}

class ExamQuestion {
  ExamQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.marks,
    this.options = const [],
    this.correctAnswer = '',
  });

  final String id;
  final QuestionType type;
  final String text;
  final int marks;
  final List<String> options;
  final String correctAnswer;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'marks': marks,
        'options': options,
        'correctAnswer': correctAnswer,
      };

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    return ExamQuestion(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: QuestionType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => QuestionType.written,
      ),
      text: json['text'] as String? ?? '',
      marks: (json['marks'] as num?)?.toInt() ?? 1,
      options: (json['options'] as List<dynamic>? ?? const []).cast<String>(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
    );
  }
}

class Exam {
  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.durationMinutes,
    required this.createdAt,
    this.instructions = 'أجب عن جميع الأسئلة، مع كتابة خطوات الحل عند الحاجة.',
    List<ExamQuestion>? questions,
  }) : questions = questions ?? [];

  final String id;
  String title;
  String subject;
  String grade;
  int durationMinutes;
  DateTime createdAt;
  String instructions;
  final List<ExamQuestion> questions;

  int get totalMarks => questions.fold(0, (sum, question) => sum + question.marks);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'grade': grade,
        'durationMinutes': durationMinutes,
        'createdAt': createdAt.toIso8601String(),
        'instructions': instructions,
        'questions': questions.map((question) => question.toJson()).toList(),
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'اختبار جديد',
        subject: json['subject'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        instructions: json['instructions'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((item) => ExamQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
