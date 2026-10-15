import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'report_generation_service.dart';

/// Turns a [ReportResult] into a PDF or CSV file and hands it to the
/// device's native share sheet, so the admin can save it, email it,
/// print it, etc.
class ExportService {
  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> exportToPdf(ReportResult report) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'SubdiServe \u2014 ${report.title}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Date range: ${_fmtDate(report.startDate)} to ${_fmtDate(report.endDate)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated: ${_fmtDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Summary',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Bullet(text: report.summaryLines.join('\n')),
          ...report.summaryLines.map((line) => pw.Bullet(text: line)),
          pw.SizedBox(height: 16),
          pw.Text('Details (${report.rows.length} records)',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (report.rows.isEmpty)
            pw.Text('No records found for this date range.')
          else
            pw.TableHelper.fromTextArray(
              headers: report.headers,
              data: report.rows,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey100),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 22,
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    final fileName =
        '${report.title.replaceAll(' ', '_')}_${_fmtDate(report.startDate)}_${_fmtDate(report.endDate)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  Future<void> exportToCsv(ReportResult report) async {
    final buffer = StringBuffer();

    String escape(String value) {
      final needsQuotes =
          value.contains(',') || value.contains('"') || value.contains('\n');
      final escaped = value.replaceAll('"', '""');
      return needsQuotes ? '"$escaped"' : escaped;
    }

    buffer.writeln('SubdiServe - ${report.title}');
    buffer.writeln(
        'Date range,${_fmtDate(report.startDate)} to ${_fmtDate(report.endDate)}');
    buffer.writeln('Generated,${_fmtDate(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('Summary');
    for (final line in report.summaryLines) {
      buffer.writeln(escape(line));
    }
    buffer.writeln();
    buffer.writeln(report.headers.map(escape).join(','));
    for (final row in report.rows) {
      buffer.writeln(row.map(escape).join(','));
    }

    final fileName =
        '${report.title.replaceAll(' ', '_')}_${_fmtDate(report.startDate)}_${_fmtDate(report.endDate)}.csv';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: report.title);
  }
}