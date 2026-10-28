import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:printing/printing.dart';

import 'models/exam.dart';
import 'services/exam_store.dart';
import 'services/pdf_service.dart';

const _ink = Color(0xFF183A35);
const _green = Color(0xFF16745D);
const _mint = Color(0xFFE7F3EE);
const _canvas = Color(0xFFF5F7F6);
const _muted = Color(0xFF75837F);

void main() => runApp(const SuwalatiApp());

class SuwalatiApp extends StatelessWidget {
  const SuwalatiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'سؤالاتي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: _green, brightness: Brightness.light),
          appBarTheme: const AppBarTheme(
            backgroundColor: _canvas,
            foregroundColor: _ink,
            centerTitle: false,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF7F9F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            hintStyle: const TextStyle(color: _muted, fontSize: 14),
            labelStyle: const TextStyle(color: _muted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4EAE7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE4EAE7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
        home: const ExamLibraryScreen(),
      );
}

class ExamLibraryScreen extends StatefulWidget {
  const ExamLibraryScreen({super.key});

  @override
  State<ExamLibraryScreen> createState() => _ExamLibraryScreenState();
}

class _ExamLibraryScreenState extends State<ExamLibraryScreen> {
  final _store = ExamStore();
  List<Exam> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final exams = await _store.load();
    if (!mounted) return;
    setState(() {
      _exams = exams..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _loading = false;
    });
  }

  Future<void> _saveAll() => _store.save(_exams);

  Future<void> _createExam() async {
    final details = await showDialog<_ExamDetails>(
      context: context,
      builder: (_) => const _ExamDetailsDialog(),
    );
    if (details == null) return;
    final exam = Exam(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: details.title,
      subject: details.subject,
      grade: details.grade,
      durationMinutes: details.durationMinutes,
      instructions: details.instructions,
      createdAt: DateTime.now(),
    );
    setState(() => _exams.insert(0, exam));
    await _saveAll();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ExamEditorScreen(
        exam: exam,
        onChanged: (_) => _saveAll(),
      ),
    ));
    await _reload();
  }

  Future<void> _openExam(Exam exam) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ExamEditorScreen(
        exam: exam,
        onChanged: (_) => _saveAll(),
      ),
    ));
    await _reload();
  }

  Future<void> _deleteExam(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الاختبار؟', textAlign: TextAlign.right),
        content: Text('سيُحذف «${exam.title}» وجميع أسئلته من هذا الجهاز.',
            textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _exams.removeWhere((item) => item.id == exam.id));
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = _exams.fold<int>(0, (sum, exam) => sum + exam.questions.length);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createExam,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('اختبار جديد', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _green,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.edit_note_rounded, color: _green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('سؤالاتي', style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('أنشئ اختبارك، واحفظه واطبعه بسهولة', style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'معلومات التطبيق',
                    onPressed: () => showAboutDialog(
                      context: context,
                      applicationName: 'سؤالاتي',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'اختباراتك محفوظة محليًا على هذا الجهاز.',
                    ),
                    icon: const Icon(Icons.info_outline_rounded, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _WelcomeBanner(onCreate: _createExam),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'الاختبارات', value: '${_exams.length}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(icon: Icons.quiz_outlined, label: 'الأسئلة', value: '$totalQuestions')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(icon: Icons.stars_rounded, label: 'الدرجات', value: '${_exams.fold<int>(0, (sum, exam) => sum + exam.totalMarks)}')),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Text('اختباراتي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink))),
                  if (_exams.isNotEmpty)
                    Text('${_exams.length} اختبارات', style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: _green)))
              else if (_exams.isEmpty)
                const _EmptyLibrary()
              else
                ..._exams.map((exam) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _ExamCard(
                        exam: exam,
                        onTap: () => _openExam(exam),
                        onDelete: () => _deleteExam(exam),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1D7B62), Color(0xFF145447)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _green.withValues(alpha: .16), blurRadius: 20, offset: const Offset(0, 9))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
                    child: const Text('إدارة الاختبارات', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  const Text('اختبار مرتب،\nبخطوات بسيطة', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('اكتب الأسئلة، حدّد الدرجات، ثم اطبع أو صدّر PDF.', style: TextStyle(color: Colors.white.withValues(alpha: .83), fontSize: 12, height: 1.5)),
                  const SizedBox(height: 17),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _green,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('ابدأ اختبارًا', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 74,
              height: 90,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 43),
            ),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
        child: Column(
          children: [
            Icon(icon, color: _green, size: 21),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      );
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap, required this.onDelete});
  final Exam exam;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 16, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.article_outlined, color: _green),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('${exam.subject}${exam.grade.isNotEmpty ? ' • ${exam.grade}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'خيارات الاختبار',
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        if (value == 'open') onTap();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('فتح وتحرير')),
                        PopupMenuItem(value: 'delete', child: Text('حذف الاختبار')),
                      ],
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: Color(0xFFEDF0EF))),
                Row(
                  children: [
                    _TinyInfo(icon: Icons.quiz_outlined, label: '${exam.questions.length} سؤال'),
                    const SizedBox(width: 16),
                    _TinyInfo(icon: Icons.stars_rounded, label: '${exam.totalMarks} درجة'),
                    const SizedBox(width: 16),
                    _TinyInfo(icon: Icons.schedule_rounded, label: '${exam.durationMinutes} دقيقة'),
                    const Spacer(),
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: _muted), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: _muted))],
      );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: const Column(
          children: [
            Icon(Icons.library_add_outlined, size: 42, color: Color(0xFF9DB7AE)),
            SizedBox(height: 12),
            Text('لا توجد اختبارات بعد', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('اضغط «اختبار جديد» وابدأ بإضافة أسئلتك.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
      );
}

class _ExamDetails {
  const _ExamDetails({required this.title, required this.subject, required this.grade, required this.durationMinutes, required this.instructions});
  final String title;
  final String subject;
  final String grade;
  final int durationMinutes;
  final String instructions;
}

class _ExamDetailsDialog extends StatefulWidget {
  const _ExamDetailsDialog({this.exam});
  final Exam? exam;

  @override
  State<_ExamDetailsDialog> createState() => _ExamDetailsDialogState();
}

class _ExamDetailsDialogState extends State<_ExamDetailsDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subject;
  late final TextEditingController _grade;
  late final TextEditingController _duration;
  late final TextEditingController _instructions;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _title = TextEditingController(text: exam?.title ?? '');
    _subject = TextEditingController(text: exam?.subject ?? '');
    _grade = TextEditingController(text: exam?.grade ?? '');
    _duration = TextEditingController(text: '${exam?.durationMinutes ?? 60}');
    _instructions = TextEditingController(text: exam?.instructions ?? 'أجب عن جميع الأسئلة، مع كتابة خطوات الحل عند الحاجة.');
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _grade.dispose();
    _duration.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.exam == null ? 'إعداد اختبار جديد' : 'بيانات الاختبار', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(_title, 'عنوان الاختبار', required: true, icon: Icons.title_rounded),
                const SizedBox(height: 11),
                _textField(_subject, 'المادة', required: true, icon: Icons.menu_book_outlined),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(child: _textField(_grade, 'الصف / المرحلة', icon: Icons.school_outlined)),
                    const SizedBox(width: 9),
                    Expanded(child: _textField(_duration, 'المدة بالدقائق', required: true, numeric: true, icon: Icons.schedule_rounded)),
                  ],
                ),
                const SizedBox(height: 11),
                _textField(_instructions, 'تعليمات الاختبار', maxLines: 2, icon: Icons.notes_rounded),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton.icon(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, _ExamDetails(
                title: _title.text.trim(),
                subject: _subject.text.trim(),
                grade: _grade.text.trim(),
                durationMinutes: int.tryParse(_duration.text) ?? 60,
                instructions: _instructions.text.trim(),
              ));
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(widget.exam == null ? 'إنشاء' : 'حفظ'),
          ),
        ],
      );

  Widget _textField(TextEditingController controller, String label, {bool required = false, bool numeric = false, int maxLines = 1, IconData? icon}) => TextFormField(
        controller: controller,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon, size: 19)),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) return 'هذا الحقل مطلوب';
          if (numeric && (int.tryParse(value ?? '') == null || int.parse(value!) < 1)) return 'أدخل رقمًا أكبر من صفر';
          return null;
        },
      );
}

class ExamEditorScreen extends StatefulWidget {
  const ExamEditorScreen({super.key, required this.exam, required this.onChanged});
  final Exam exam;
  final Future<void> Function(Exam exam) onChanged;

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  bool _busy = false;

  Future<void> _persist() => widget.onChanged(widget.exam);

  Future<void> _editDetails() async {
    final details = await showDialog<_ExamDetails>(
      context: context,
      builder: (_) => _ExamDetailsDialog(exam: widget.exam),
    );
    if (details == null) return;
    setState(() {
      widget.exam
        ..title = details.title
        ..subject = details.subject
        ..grade = details.grade
        ..durationMinutes = details.durationMinutes
        ..instructions = details.instructions;
    });
    await _persist();
  }

  Future<void> _addQuestion({ExamQuestion? existing}) async {
    final question = await showModalBottomSheet<ExamQuestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionEditorSheet(question: existing),
    );
    if (question == null) return;
    setState(() {
      if (existing == null) {
        widget.exam.questions.add(question);
      } else {
        final index = widget.exam.questions.indexWhere((item) => item.id == existing.id);
        if (index >= 0) widget.exam.questions[index] = question;
      }
    });
    await _persist();
  }

  Future<void> _deleteQuestion(ExamQuestion question) async {
    setState(() => widget.exam.questions.removeWhere((item) => item.id == question.id));
    await _persist();
  }

  Future<bool?> _askAnswerKey() => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('نموذج الإجابة', textAlign: TextAlign.right),
          content: const Text('هل تريد إرفاق نموذج الإجابة في نهاية الملف؟', textAlign: TextAlign.right),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('بدون نموذج')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إرفاق النموذج')),
          ],
        ),
      );

  Future<void> _makePdf({required bool print}) async {
    if (widget.exam.questions.isEmpty) {
      _message('أضف سؤالًا واحدًا على الأقل قبل إنشاء ملف PDF.');
      return;
    }
    final includeKey = await _askAnswerKey();
    if (includeKey == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await ExamPdfService.create(widget.exam, includeAnswerKey: includeKey);
      final safeTitle = widget.exam.title.replaceAll(RegExp(r'[/\\:*?"<>|]'), '-').trim();
      final filename = '${safeTitle.isEmpty ? 'اختبار' : safeTitle}.pdf';
      if (print) {
        await Printing.layoutPdf(name: filename, onLayout: (_) async => bytes);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (error) {
      if (mounted) _message('تعذّر تجهيز الملف. تحقق من صلاحية الخط وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, textAlign: TextAlign.right)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('محرّر الاختبار', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(tooltip: 'طباعة', onPressed: _busy ? null : () => _makePdf(print: true), icon: const Icon(Icons.print_outlined)),
            IconButton(tooltip: 'حفظ أو مشاركة PDF', onPressed: _busy ? null : () => _makePdf(print: false), icon: const Icon(Icons.picture_as_pdf_outlined)),
            const SizedBox(width: 5),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addQuestion(),
          backgroundColor: _green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة سؤال', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: _busy
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: _green), SizedBox(height: 14), Text('جارٍ تجهيز ملف PDF…', style: TextStyle(color: _muted))]))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 105),
                  children: [
                    _ExamSummaryCard(exam: widget.exam, onEdit: _editDetails),
                    const SizedBox(height: 23),
                    Row(
                      children: [
                        const Expanded(child: Text('أسئلة الاختبار', style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(20)),
                          child: Text('${widget.exam.questions.length} سؤال · ${widget.exam.totalMarks} درجة', style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.exam.questions.isEmpty)
                      const _EmptyQuestions()
                    else
                      ...widget.exam.questions.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuestionCard(
                              index: entry.key + 1,
                              question: entry.value,
                              onEdit: () => _addQuestion(existing: entry.value),
                              onDelete: () => _deleteQuestion(entry.value),
                            ),
                          )),
                  ],
                ),
        ),
      );
}

class _ExamSummaryCard extends StatelessWidget {
  const _ExamSummaryCard({required this.exam, required this.onEdit});
  final Exam exam;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(exam.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800))),
                IconButton(onPressed: onEdit, tooltip: 'تعديل البيانات', icon: const Icon(Icons.edit_outlined, color: _green, size: 20)),
              ],
            ),
            Text('${exam.subject}${exam.grade.isEmpty ? '' : ' • ${exam.grade}'}', style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _SummaryMetric(icon: Icons.schedule_rounded, value: '${exam.durationMinutes} دقيقة', label: 'المدة')),
                Expanded(child: _SummaryMetric(icon: Icons.quiz_outlined, value: '${exam.questions.length}', label: 'الأسئلة')),
                Expanded(child: _SummaryMetric(icon: Icons.stars_rounded, value: '${exam.totalMarks}', label: 'الدرجة الكلية')),
              ],
            ),
          ],
        ),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700)), Text(label, style: const TextStyle(color: _muted, fontSize: 10))]),
        ],
      );
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Column(
          children: [
            Icon(Icons.playlist_add_rounded, color: Color(0xFF91ADA3), size: 40),
            SizedBox(height: 10),
            Text('ابدأ ببناء اختبارك', style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('أضف اختيارًا من متعدد، صح وخطأ، أو سؤالًا تحريريًا.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12, height: 1.5)),
          ],
        ),
      );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.question, required this.onEdit, required this.onDelete});
  final int index;
  final ExamQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 13, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(9)),
                    child: Text('سؤال $index', style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(question.type.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11))),
                  Text('${question.marks} د', style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800)),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 140),
                    onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل السؤال')),
                      PopupMenuItem(value: 'delete', child: Text('حذف السؤال')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.text, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontSize: 14, height: 1.5)),
              if (question.type == QuestionType.multipleChoice && question.options.isNotEmpty) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: question.options.asMap().entries.map((entry) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF5F7F6), borderRadius: BorderRadius.circular(8)),
                    child: Text('${const ['أ', 'ب', 'ج', 'د'][entry.key % 4]}. ${entry.value}', style: const TextStyle(color: _muted, fontSize: 11)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      );
}

class _QuestionEditorSheet extends StatefulWidget {
  const _QuestionEditorSheet({this.question});
  final ExamQuestion? question;

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final TextEditingController _marks;
  late final TextEditingController _answer;
  late final List<TextEditingController> _options;
  late QuestionType _type;
  int _correctOption = 0;
  String _trueFalseAnswer = 'صح';

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _type = question?.type ?? QuestionType.multipleChoice;
    _text = TextEditingController(text: question?.text ?? '');
    _marks = TextEditingController(text: '${question?.marks ?? 1}');
    _answer = TextEditingController(text: question?.correctAnswer ?? '');
    _options = List.generate(4, (index) => TextEditingController(
      text: question != null && index < question.options.length ? question.options[index] : '',
    ));
    if (_type == QuestionType.multipleChoice) _correctOption = int.tryParse(question?.correctAnswer ?? '') ?? 0;
    if (_type == QuestionType.trueFalse && question?.correctAnswer.isNotEmpty == true) _trueFalseAnswer = question!.correctAnswer;
  }

  @override
  void dispose() {
    _text.dispose();
    _marks.dispose();
    _answer.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .88,
        minChildSize: .62,
        maxChildSize: .96,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: _canvas, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 25),
              children: [
                Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFD5DEDA), borderRadius: BorderRadius.circular(5)))),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Text(widget.question == null ? 'إضافة سؤال' : 'تعديل السؤال', style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _muted)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<QuestionType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'نوع السؤال', prefixIcon: Icon(Icons.category_outlined)),
                  items: QuestionType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'نص السؤال', alignLabelWithHint: true, prefixIcon: Icon(Icons.help_outline_rounded)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'اكتب نص السؤال' : null,
                ),
                const SizedBox(height: 12),
                if (_type == QuestionType.multipleChoice) ..._buildOptions(),
                if (_type == QuestionType.trueFalse) _buildTrueFalse(),
                if (_type == QuestionType.written || _type == QuestionType.fillBlank) ...[
                  TextFormField(
                    controller: _answer,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: _type == QuestionType.written ? 2 : 1,
                    decoration: InputDecoration(
                      labelText: _type == QuestionType.written ? 'إجابة نموذجية (اختياري)' : 'الإجابة الصحيحة (اختياري)',
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _marks,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'درجة السؤال', prefixIcon: Icon(Icons.stars_outlined)),
                  validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) < 1 ? 'أدخل درجة صحيحة أكبر من صفر' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.question == null ? 'إضافة السؤال' : 'حفظ التعديلات', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  List<Widget> _buildOptions() {
    final labels = const ['أ', 'ب', 'ج', 'د'];
    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('الخيارات — اختر الإجابة الصحيحة', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      ...List.generate(4, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Radio<int>(value: index, groupValue: _correctOption, activeColor: _green, onChanged: (value) => setState(() => _correctOption = value ?? 0)),
            Expanded(
              child: TextFormField(
                controller: _options[index],
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: 'الخيار ${labels[index]}', isDense: true),
                validator: index < 2 ? (value) => value == null || value.trim().isEmpty ? 'أدخل هذا الخيار' : null : null,
              ),
            ),
          ],
        ),
      )),
    ];
  }

  Widget _buildTrueFalse() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('الإجابة الصحيحة', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600))),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'صح', label: Text('صح'), icon: Icon(Icons.check_rounded)),
                ButtonSegment(value: 'خطأ', label: Text('خطأ'), icon: Icon(Icons.close_rounded)),
              ],
              selected: {_trueFalseAnswer},
              onSelectionChanged: (selection) => setState(() => _trueFalseAnswer = selection.first),
            ),
          ],
        ),
      );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final options = _type == QuestionType.multipleChoice
        ? _options.map((controller) => controller.text.trim()).where((value) => value.isNotEmpty).toList()
        : <String>[];
    final correctAnswer = switch (_type) {
      QuestionType.multipleChoice => '$_correctOption',
      QuestionType.trueFalse => _trueFalseAnswer,
      QuestionType.written || QuestionType.fillBlank => _answer.text.trim(),
    };
    Navigator.pop(context, ExamQuestion(
      id: widget.question?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      text: _text.text.trim(),
      marks: int.parse(_marks.text),
      options: options,
      correctAnswer: correctAnswer,
    ));
  }
}