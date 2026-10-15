import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/booking_service.dart';

/// Shows a "Decline Booking" dialog (provider side): requires a reason,
/// then transitions the booking to 'rejected'.
Future<bool> showDeclineBookingDialog({
  required BuildContext context,
  required String bookingId,
  required String serviceName,
}) async {
  return _showReasonDialog(
    context: context,
    title: 'Decline this booking?',
    subtitle:
        'Let the homeowner know why you can\'t take "$serviceName" right now.',
    hint: 'Reason for declining (required)...',
    confirmLabel: 'Decline',
    confirmColor: const Color(0xFFEF4444),
    onConfirm: (reason) => BookingService().updateBookingStatus(
      bookingId: bookingId,
      newStatus: 'rejected',
      reason: reason,
    ),
  );
}

/// Shows a "Cancel Booking" dialog (homeowner side): requires a reason,
/// then transitions the booking to 'cancelled'.
Future<bool> showCancelBookingDialog({
  required BuildContext context,
  required String bookingId,
  required String serviceName,
}) async {
  return _showReasonDialog(
    context: context,
    title: 'Cancel this booking?',
    subtitle: 'Let the provider know why you\'re cancelling "$serviceName".',
    hint: 'Reason for cancelling (required)...',
    confirmLabel: 'Cancel Booking',
    confirmColor: const Color(0xFFEF4444),
    onConfirm: (reason) => BookingService().updateBookingStatus(
      bookingId: bookingId,
      newStatus: 'cancelled',
      reason: reason,
      cancelledBy: 'homeowner',
    ),
  );
}

/// Shows a "Reschedule Booking" dialog: pick a new date + time, with an
/// optional reason, then applies the change immediately.
Future<bool> showRescheduleBookingDialog({
  required BuildContext context,
  required String bookingId,
  required String serviceName,
  required String rescheduledBy, // 'homeowner' or 'provider'
}) async {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final reasonController = TextEditingController();
  bool isSubmitting = false;
  bool confirmed = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          String fmtDate(DateTime d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

          String fmtTime(TimeOfDay t) {
            final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
            final minute = t.minute.toString().padLeft(2, '0');
            final period = t.period == DayPeriod.am ? 'AM' : 'PM';
            return '$hour:$minute $period';
          }

          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: dialogContext,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF38BDF8),
                    surface: Color(0xFF0F172A),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDialogState(() => selectedDate = picked);
            }
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: dialogContext,
              initialTime: TimeOfDay.now(),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF38BDF8),
                    surface: Color(0xFF0F172A),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDialogState(() => selectedTime = picked);
            }
          }

          Future<void> submit() async {
            if (selectedDate == null || selectedTime == null) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                    content: Text('Please pick both a date and a time.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              final newDateTime = DateTime(
                selectedDate!.year,
                selectedDate!.month,
                selectedDate!.day,
                selectedTime!.hour,
                selectedTime!.minute,
              );

              await BookingService().rescheduleBooking(
                bookingId: bookingId,
                newDateTime: newDateTime,
                newBookingDate: fmtDate(selectedDate!),
                newBookingTime: fmtTime(selectedTime!),
                rescheduledBy: rescheduledBy,
                reason: reasonController.text,
              );
              confirmed = true;

              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to reschedule: $e')),
                );
              }
            } finally {
              setDialogState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            title: Text(
              'Reschedule "$serviceName"',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickDate,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded,
                            size: 16, color: Color(0xFF38BDF8)),
                        label: Text(
                          selectedDate != null
                              ? fmtDate(selectedDate!)
                              : 'Pick date',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickTime,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.access_time_rounded,
                            size: 16, color: Color(0xFF38BDF8)),
                        label: Text(
                          selectedTime != null
                              ? fmtTime(selectedTime!)
                              : 'Pick time',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Reason for rescheduling (optional)...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text('Reschedule',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return confirmed;
}

Future<bool> _showReasonDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String hint,
  required String confirmLabel,
  required Color confirmColor,
  required Future<void> Function(String reason) onConfirm,
}) async {
  final reasonController = TextEditingController();
  bool isSubmitting = false;
  bool confirmed = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Please enter a reason.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              await onConfirm(reasonController.text);
              confirmed = true;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            } finally {
              setDialogState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side:
                  BorderSide(color: confirmColor.withValues(alpha: 0.2)),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Never mind',
                    style: GoogleFonts.poppins(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(confirmLabel,
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return confirmed;
}