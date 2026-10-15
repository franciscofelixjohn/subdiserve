import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/export_service.dart';
import '../../services/report_generation_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ReportGenerationService _reportService = ReportGenerationService();
  final ExportService _exportService = ExportService();

  final List<String> _reportTypes = const [
    'Booking Report',
    'User Activity Report',
    'Provider Performance Report',
    'Ratings Report',
  ];

  String _selectedType = 'Booking Report';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isGenerating = false;
  bool _isExporting = false;
  ReportResult? _result;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              surface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _result = null; // stale until regenerated
      });
    }
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      ReportResult result;
      switch (_selectedType) {
        case 'User Activity Report':
          result =
              await _reportService.generateUserActivityReport(_startDate, _endDate);
          break;
        case 'Provider Performance Report':
          result = await _reportService.generateProviderPerformanceReport(
              _startDate, _endDate);
          break;
        case 'Ratings Report':
          result =
              await _reportService.generateRatingsReport(_startDate, _endDate);
          break;
        default:
          result =
              await _reportService.generateBookingReport(_startDate, _endDate);
      }

      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _export(bool asPdf) async {
    if (_result == null) return;
    setState(() => _isExporting = true);
    try {
      if (asPdf) {
        await _exportService.exportToPdf(_result!);
      } else {
        await _exportService.exportToCsv(_result!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Reports',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Type',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reportTypes.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = type;
                        _result = null;
                      });
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: const Color(0xFF0284C7),
                    side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF38BDF8)
                            : Colors.white.withValues(alpha: 0.1)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Date Range',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_fmtDate(_startDate)}  \u2192  ${_fmtDate(_endDate)}',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.insights_rounded, size: 18),
                  label: Text('Generate Report',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result!.title,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmtDate(_result!.startDate)} to ${_fmtDate(_result!.endDate)}',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      ..._result!.summaryLines.map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 5, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 8),
                                Text(line,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : () => _export(true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            foregroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 16),
                          label: Text('Export PDF',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : () => _export(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981)),
                            foregroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.table_chart_rounded,
                              size: 16),
                          label: Text('Export CSV',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Preview (${_result!.rows.length} records)',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (_result!.rows.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('No records found for this date range.',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 12)),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.05)),
                      columns: _result!.headers
                          .map((h) => DataColumn(
                              label: Text(h,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))))
                          .toList(),
                      rows: _result!.rows
                          .map((row) => DataRow(
                              cells: row
                                  .map((cell) => DataCell(Text(cell,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 11))))
                                  .toList()))
                          .toList(),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}