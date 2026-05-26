import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/app_provider.dart';
import '../../constants/theme_constants.dart';

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  String? _selectedSemester;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<AppProvider>(context, listen: false);
      if (p.semesters.isNotEmpty) {
        setState(() => _selectedSemester = p.semesters.last);
      }
    });
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    final p = Provider.of<AppProvider>(context, listen: false);
    final student = p.currentStudent;
    final grades = p.getGradesForSemester(_selectedSemester!);
    final gpa = p.selectedGPA;
    final cgpa = p.cgpa;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              color: PdfColors.indigo,
              child: pw.Text('Digital Grade-Report Locker',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${student?.fullName ?? ''}',
                        style:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('ID: ${student?.studentId ?? ''}'),
                    pw.Text('Dept: ${student?.department ?? ''}'),
                    pw.Text('Batch: ${student?.batch ?? ''}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Semester: $_selectedSemester'),
                    pw.Text('GPA: ${gpa.toStringAsFixed(2)}'),
                    pw.Text('CGPA: ${cgpa.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Academic Results',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Code'),
                    _th('Title'),
                    _th('Credits'),
                    _th('Mid'),
                    _th('Assign'),
                    _th('Final'),
                    _th('Total'),
                    _th('Grade'),
                  ],
                ),
                ...grades.map((g) {
                  final c = p.getCourseInfo(g.courseCode);
                  return pw.TableRow(children: [
                    _td(g.courseCode),
                    _td(c?.courseTitle ?? ''),
                    _td('${c?.creditHours ?? 0}'),
                    _td(g.midScore.toStringAsFixed(1)),
                    _td(g.assignmentScore.toStringAsFixed(1)),
                    _td(g.finalScore.toStringAsFixed(1)),
                    _td(g.totalScore.toStringAsFixed(1)),
                    _td(g.letterGrade),
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                  'Generated: ${DateTime.now().toString().split('.')[0]}',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
          ],
        ),
      ),
    );

    setState(() => _isLoading = false);
    await Printing.layoutPdf(
      onLayout: (f) async => pdf.save(),
      name: 'Academic_Report_$_selectedSemester.pdf',
    );
  }

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _td(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('PDF Report'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Semester', style: AppTextStyles.h3),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSemester,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.primary,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white),
                    items: provider.semesters.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSemester = v),
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedSemester != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.whiteCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Report Preview',
                            style: AppTextStyles.h3),
                        const SizedBox(height: 14),
                        _previewRow('Student',
                            provider.currentStudent?.fullName ?? ''),
                        _previewRow('Semester', _selectedSemester!),
                        _previewRow(
                            'GPA',
                            provider.selectedGPA.toStringAsFixed(2)),
                        _previewRow(
                            'CGPA', provider.cgpa.toStringAsFixed(2)),
                        _previewRow(
                            'Courses',
                            '${provider.getGradesForSemester(_selectedSemester!).length}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      _isLoading
                          ? 'Generating...'
                          : 'Generate & Download PDF',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    onPressed: _isLoading || _selectedSemester == null
                        ? null
                        : _generatePdf,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
