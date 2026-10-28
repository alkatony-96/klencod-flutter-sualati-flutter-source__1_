import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam.dart';

class ExamPdfService {
  static Future<Uint8List> create(Exam exam, {required bool includeAnswerKey}) async {
    final regularData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: exam.title,
      author: 'سؤالاتي',
      subject: exam.subject,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 36),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            textDirection: pw.TextDirection.rtl,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 14),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1.4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  exam.title,
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: bold, fontSize: 21, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _meta('المادة', exam.subject, regular, bold),
                    _meta('الصف', exam.grade.isEmpty ? '—' : exam.grade, regular, bold),
                    _meta('المدة', '${exam.durationMinutes} دقيقة', regular, bold),
                    _meta('الدرجة', '${exam.totalMarks}', regular, bold),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            textDirection: pw.TextDirection.rtl,
            children: [
              pw.Expanded(child: _identityLine('اسم الطالب')),
              pw.SizedBox(width: 18),
              pw.Expanded(child: _identityLine('الشعبة')),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              exam.instructions,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 15),
          ...exam.questions.asMap().entries.map((entry) => _question(
                entry.key + 1,
                entry.value,
                regular,
                bold,
              )),
          if (exam.questions.isEmpty)
            pw.Text(
              'لا توجد أسئلة في هذا الاختبار بعد.',
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: PdfColors.grey600),
            ),
          if (includeAnswerKey && exam.questions.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Container(height: 1, color: PdfColors.blueGrey300),
            pw.SizedBox(height: 12),
            pw.Text(
              'نموذج الإجابة — للمدرّس',
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),
            ...exam.questions.asMap().entries.map((entry) => _answer(
                  entry.key + 1,
                  entry.value,
                  regular,
                  bold,
                )),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _meta(String label, String value, pw.Font regular, pw.Font bold) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: bold, fontSize: 10)),
        ],
      );

  static pw.Widget _identityLine(String label) => pw.Row(
        textDirection: pw.TextDirection.rtl,
        children: [
          pw.Text('$label: ',
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(child: pw.Container(height: 15, decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6)),
          ))),
        ],
      );

  static pw.Widget _question(int number, ExamQuestion question, pw.Font regular, pw.Font bold) {
    final content = <pw.Widget>[
      pw.Row(
        textDirection: pw.TextDirection.rtl,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$number.  ${question.text}',
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: bold, fontSize: 12, lineSpacing: 2),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('(${question.marks} ${question.marks == 1 ? 'درجة' : 'درجات'})',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    ];

    if (question.type == QuestionType.multipleChoice) {
      content.add(pw.SizedBox(height: 5));
      for (var i = 0; i < question.options.length; i++) {
        content.add(pw.Padding(
          padding: const pw.EdgeInsets.only(right: 18, top: 2),
          child: pw.Text(
            '${_optionLetter(i)}.  ${question.options[i]}',
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: regular, fontSize: 11),
          ),
        ));
      }
    } else if (question.type == QuestionType.trueFalse) {
      content.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, right: 18),
        child: pw.Text('(     ) صح          (     ) خطأ',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: regular, fontSize: 11)),
      ));
    } else if (question.type == QuestionType.written) {
      content.add(pw.SizedBox(height: 16));
      content.addAll(List.generate(
        question.marks.clamp(2, 5).toInt(),
        (_) => pw.Container(
          height: 22,
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.45))),
        ),
      ));
    } else {
      content.add(pw.SizedBox(height: 9));
      content.add(pw.Container(
        height: 20,
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.55))),
      ));
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 13),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.45))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  static pw.Widget _answer(int number, ExamQuestion question, pw.Font regular, pw.Font bold) {
    String answer;
    switch (question.type) {
      case QuestionType.multipleChoice:
        final index = int.tryParse(question.correctAnswer);
        answer = index != null && index >= 0 && index < question.options.length
            ? '${_optionLetter(index)}. ${question.options[index]}'
            : 'لم تُحدّد الإجابة';
        break;
      case QuestionType.trueFalse:
        answer = question.correctAnswer.isEmpty ? 'لم تُحدّد الإجابة' : question.correctAnswer;
        break;
      case QuestionType.fillBlank:
      case QuestionType.written:
        answer = question.correctAnswer.isEmpty ? 'تُصحّح تحريريًا' : question.correctAnswer;
        break;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        textDirection: pw.TextDirection.rtl,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$number.  ',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: bold, fontSize: 10)),
          pw.Expanded(
            child: pw.Text(answer,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: regular, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static String _optionLetter(int index) => const ['أ', 'ب', 'ج', 'د', 'هـ', 'و'][index % 6];
}
