import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';

/// Complete, production-ready PDF Report Preview screen.
/// This file is self-contained and implements the high-fidelity layout
/// requested: AppBar, centered white document card, institutional header,
/// metadata grid, structured grades table, totals summary, and a bottom
/// 'Download PDF' action wired to the existing PDF generation pipeline.
class PdfReportPreviewScreen extends StatefulWidget {
  const PdfReportPreviewScreen({super.key});

  @override
  State<PdfReportPreviewScreen> createState() => _PdfReportPreviewScreenState();
}

class _PdfReportPreviewScreenState extends State<PdfReportPreviewScreen> {
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

  Future<pw.Document> _buildPdfDocument() async {
    final p = Provider.of<AppProvider>(context, listen: false);
    final student = p.currentStudent;
    final semester = _selectedSemester ?? p.semesters.lastOrNull ?? '';
    final grades = p.getGradesForSemester(semester);
    final gpa = p.selectedGPA;
    final cgpa = p.cgpa;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColors.white,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Institutional Header
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Container(
                  width: 56,
                  height: 56,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0B66C3),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(child: pw.Icon(pw.IconData(0xe88e), color: PdfColors.white, size: 28)),
                ),
                pw.SizedBox(width: 12),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Digital Grade-Report Locker', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E))),
                  pw.SizedBox(height: 4),
                  pw.Text('Official Academic Report', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.w500, color: PdfColor.fromInt(0xFF7F8FA6))),
                ])
              ]),

              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Student Metadata Grid (2-column)
              pw.Row(children: [
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [pw.Container(width: 90, child: pw.Text('Name:', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF9AA3B2)))), pw.SizedBox(width: 8), pw.Text(student?.fullName ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E)))]) ,
                  pw.SizedBox(height: 6),
                  pw.Row(children: [pw.Container(width: 90, child: pw.Text('Department:', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF9AA3B2)))), pw.SizedBox(width: 8), pw.Text(student?.department ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E)))])
                ])),

                pw.SizedBox(width: 24),

                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [pw.Container(width: 90, child: pw.Text('Student ID:', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF9AA3B2)))), pw.SizedBox(width: 8), pw.Text(student?.studentId ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E)))]) ,
                  pw.SizedBox(height: 6),
                  pw.Row(children: [pw.Container(width: 90, child: pw.Text('Batch:', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF9AA3B2)))), pw.SizedBox(width: 8), pw.Text(student?.batch ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E)))])
                ])),
              ]),

              pw.SizedBox(height: 18),

              // Semester centered label
              pw.Align(alignment: pw.Alignment.center, child: pw.Text(semester, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A1A2E)))),

              pw.SizedBox(height: 12),

              // Table header container
              pw.Container(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF3FC), borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(8), topRight: pw.Radius.circular(8))),
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Row(children: [
                  pw.Expanded(flex: 1, child: pw.Center(child: pw.Text('Course Code', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D3A7A))))),
                  pw.Expanded(flex: 4, child: pw.Center(child: pw.Text('Course Title', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D3A7A))))),
                  pw.Container(width: 50, child: pw.Center(child: pw.Text('Credit', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D3A7A))))),
                  pw.Container(width: 50, child: pw.Center(child: pw.Text('Grade', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D3A7A))))),
                  pw.Container(width: 65, child: pw.Center(child: pw.Text('Grade Point', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D3A7A))))),
                ]),
              ),

              // Table rows
              pw.Column(children: [
                for (var i = 0; i < grades.length; i++)
                  pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF3F4F6), width: 1))),
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 1, child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text(grades[i].courseCode ?? '', style: pw.TextStyle(fontSize: 12)))),
                      pw.Expanded(flex: 4, child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text(p.getCourseInfo(grades[i].courseCode)?.courseTitle ?? '', style: pw.TextStyle(fontSize: 12)))),
                      pw.Container(width: 50, child: pw.Center(child: pw.Text('${p.getCourseInfo(grades[i].courseCode)?.creditHours ?? 0}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)))) ,
                      pw.Container(width: 50, child: pw.Center(child: pw.Text(grades[i].letterGrade ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)))) ,
                      pw.Container(width: 65, child: pw.Center(child: pw.Text(_pdfGradePointString(grades[i].letterGrade ?? ''), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)))) ,
                    ]),
                  ),
              ]),

              pw.SizedBox(height: 12),

              // Totals summary
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Total Credit Hours: ${_pdfTotalCredits(p, semester)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Row(children: [
                    pw.Text('GPA: ${gpa.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 20),
                    pw.Text('CGPA: ${cgpa.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ])
                ]),
              ),

              pw.Spacer(),

              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)))
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  String _pdfGradePointString(String letter) {
    final gp = _gradePointFromLetter(letter);
    return gp.toStringAsFixed(2);
  }

  double _gradePointFromLetter(String letter) {
    switch ((letter ?? '').toUpperCase()) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }

  int _pdfTotalCredits(AppProvider p, String semester) {
    final grades = p.getGradesForSemester(semester);
    int total = 0;
    for (final g in grades) {
      final c = p.getCourseInfo(g.courseCode);
      total += (c?.creditHours ?? 0);
    }
    return total;
  }

  Future<void> _generatePdf() async {
    if (_selectedSemester == null) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _buildPdfDocument();
      await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Academic_Report_${_selectedSemester}.pdf');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_selectedSemester == null) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _buildPdfDocument();
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'Academic_Report_${_selectedSemester}.pdf');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _metaKey(String key) {
    return Text(key, style: const TextStyle(fontSize: 12, color: Colors.grey));
  }

  Widget _metaValue(String value) {
    return Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final student = provider.currentStudent;
      final semester = _selectedSemester ?? (provider.semesters.isNotEmpty ? provider.semesters.last : '');
      final grades = semester.isEmpty ? <dynamic>[] : provider.getGradesForSemester(semester);

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        // Top safe area color: draw a small Container to simulate colored safe area
        appBar: AppBar(
          title: const Text('Report Preview'),
          backgroundColor: const Color(0xFF0B66C3),
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.share_outlined), onPressed: _isLoading ? null : _sharePdf),
            IconButton(icon: const Icon(Icons.sync_rounded), onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await provider.loadStudentData();
                if (provider.semesters.isNotEmpty && _selectedSemester == null) setState(() => _selectedSemester = provider.semesters.last);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }),
          ],
        ),
        body: Column(children: [
          // top safe area color fill
          Container(height: MediaQuery.of(context).padding.top, color: const Color(0xFF0B66C3)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Institutional header
                          Row(children: [
                            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF0B66C3), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 28))),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                              Text('Digital Grade-Report Locker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                              SizedBox(height: 4),
                              Text('Official Academic Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF7F8FA6))),
                            ])
                          ]),

                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),

                          // Metadata grid
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const SizedBox(width: 90, child: Text('Name:', style: TextStyle(color: Colors.grey, fontSize: 12))), const SizedBox(width: 8), Text(student?.fullName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))]),
                              const SizedBox(height: 8),
                              Row(children: [const SizedBox(width: 90, child: Text('Department:', style: TextStyle(color: Colors.grey, fontSize: 12))), const SizedBox(width: 8), Text(student?.department ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))])
                            ])),

                            const SizedBox(width: 24),

                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const SizedBox(width: 90, child: Text('Student ID:', style: TextStyle(color: Colors.grey, fontSize: 12))), const SizedBox(width: 8), Text(student?.studentId ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))]),
                              const SizedBox(height: 8),
                              Row(children: [const SizedBox(width: 90, child: Text('Batch:', style: TextStyle(color: Colors.grey, fontSize: 12))), const SizedBox(width: 8), Text(student?.batch ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))])
                            ])),
                          ])),

                          const SizedBox(height: 6),

                          // Semester label
                          Center(child: Text(semester, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
                          const SizedBox(height: 12),

                          // Grades table header
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFEBF3FC), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Row(children: const [
                              SizedBox(width: 70, child: Center(child: Text('Course Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D3A7A))))),
                              Expanded(child: Center(child: Text('Course Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D3A7A))))),
                              SizedBox(width: 50, child: Center(child: Text('Credit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D3A7A))))),
                              SizedBox(width: 50, child: Center(child: Text('Grade', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D3A7A))))),
                              SizedBox(width: 65, child: Center(child: Text('Grade Point', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D3A7A))))),
                            ]),
                          ),

                          // Data rows
                          Expanded(child: ListView.builder(padding: const EdgeInsets.only(top: 0), itemCount: grades.length == 0 ? 1 : grades.length, itemBuilder: (ctx, idx) {
                            if (grades.isEmpty) {
                              return Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1))), child: const Text('No grades available for this semester', style: TextStyle(color: Colors.grey)));
                            }
                            final g = grades[idx];
                            final c = provider.getCourseInfo(g.courseCode);
                            return Container(
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1))),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(children: [
                                SizedBox(width: 70, child: Text(g.courseCode ?? '', style: const TextStyle(fontSize: 13))),
                                Expanded(child: Text(c?.courseTitle ?? '', style: const TextStyle(fontSize: 13))),
                                SizedBox(width: 50, child: Center(child: Text('${c?.creditHours ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                                SizedBox(width: 50, child: Center(child: Text(g.letterGrade ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                                SizedBox(width: 65, child: Center(child: Text(_gradePointFromLetter(g.letterGrade ?? '').toStringAsFixed(2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                              ]),
                            );
                          })),

                          const SizedBox(height: 12),

                          // Totals summary
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Total Credit Hours: ${_calculateTotalCredits(provider, semester)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Row(children: [Text('GPA: ${provider.selectedGPA.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 24), Text('CGPA: ${provider.cgpa.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))])
                            ]),
                          ),

                        ]),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bottom action button
                    SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: (_isLoading || _selectedSemester == null) ? null : _generatePdf, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Download PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),

                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  int _calculateTotalCredits(AppProvider p, String semester) {
    if (semester.isEmpty) return 0;
    final grades = p.getGradesForSemester(semester);
    int total = 0;
    for (final g in grades) {
      final c = p.getCourseInfo(g.courseCode);
      total += (c?.creditHours ?? 0);
    }
    return total;
  }
}

extension _ListHelpers<E> on List<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
