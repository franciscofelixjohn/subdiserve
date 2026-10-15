import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/progress_timeline.dart';
import '../chat/chat_screen.dart';

class ProviderBookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const ProviderBookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<ProviderBookingDetailsScreen> createState() =>
      _ProviderBookingDetailsScreenState();
}

class _ProviderBookingDetailsScreenState
    extends State<ProviderBookingDetailsScreen> {
  final BookingService _bookingService = BookingService();

  bool _isAccepting = false;
  bool _isRejecting = false;
  bool _isCompleting = false;

  BookingModel get booking => widget.booking;

  String _formatLabel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'accepted':
        return const Color(0xFF38BDF8); // Electric Cyan
      case 'rejected':
        return const Color(0xFFEF4444); // Soft Red
      case 'completed':
        return const Color(0xFF10B981); // Emerald Green
      default:
        return Colors.white70;
    }
  }

  Future<bool> _showActionConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0C2340),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _updateBookingStatus({
    required String newStatus,
    required String successMessage,
    required String errorMessage,
    required VoidCallback setLoadingTrue,
    required VoidCallback setLoadingFalse,
    required String dialogTitle,
    required String dialogMessage,
    required String dialogConfirmText,
    required Color dialogConfirmColor,
  }) async {
    final confirmed = await _showActionConfirmationDialog(
      title: dialogTitle,
      message: dialogMessage,
      confirmText: dialogConfirmText,
      confirmColor: dialogConfirmColor,
    );

    if (!confirmed) return;

    setState(setLoadingTrue);

    try {
      await _bookingService.updateBookingStatus(
        bookingId: booking.id,
        newStatus: newStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(setLoadingFalse);
      }
    }
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isHidden = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: GoogleFonts.poppins(
                color: isHidden ? const Color(0xFFF59E0B) : Colors.white,
                fontSize: 13,
                fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                fontWeight: isHidden ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = booking.status.toLowerCase();

    return Column(
      children: [
        // Chat button laging available para makapag-chat muna bago i-accept ang trabaho
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: booking.clientId,
                    otherUserName: booking.clientName,
                    bookingId: booking.id,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
              foregroundColor: const Color(0xFF38BDF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: Text(
              'Chat with Client (Pre-evaluation)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isAccepting || _isRejecting
                        ? null
                        : () {
                            _updateBookingStatus(
                              newStatus: 'accepted',
                              successMessage: 'Booking accepted successfully.',
                              errorMessage: 'Failed to accept booking',
                              setLoadingTrue: () => _isAccepting = true,
                              setLoadingFalse: () => _isAccepting = false,
                              dialogTitle: 'Accept booking?',
                              dialogMessage:
                                  'Are you sure you want to accept this booking request? Detailed homeowner address will now be unlocked.',
                              dialogConfirmText: 'Accept',
                              dialogConfirmColor: const Color(0xFF0284C7),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Accept',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isAccepting || _isRejecting
                        ? null
                        : () {
                            _updateBookingStatus(
                              newStatus: 'rejected',
                              successMessage: 'Booking rejected successfully.',
                              errorMessage: 'Failed to reject booking',
                              setLoadingTrue: () => _isRejecting = true,
                              setLoadingFalse: () => _isRejecting = false,
                              dialogTitle: 'Reject booking?',
                              dialogMessage:
                                  'Are you sure you want to reject this booking request?',
                              dialogConfirmText: 'Reject',
                              dialogConfirmColor: const Color(0xFFEF4444),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isRejecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        : Text(
                            'Reject',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],

        if (status == 'accepted') ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isCompleting
                  ? null
                  : () {
                      _updateBookingStatus(
                        newStatus: 'completed',
                        successMessage: 'Booking marked as completed.',
                        errorMessage: 'Failed to complete booking',
                        setLoadingTrue: () => _isCompleting = true,
                        setLoadingFalse: () => _isCompleting = false,
                        dialogTitle: 'Complete booking?',
                        dialogMessage:
                            'Are you sure you want to mark this booking as completed?',
                        dialogConfirmText: 'Complete',
                        dialogConfirmColor: const Color(0xFF10B981),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Mark as Completed',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final isAcceptedOrCompleted = booking.status.toLowerCase() == 'accepted' ||
        booking.status.toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Deep Obsidian Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020408),
                  Color(0xFF061021),
                  Color(0xFF0B192C),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Details Card (Consistent Dark Navy Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0C2340), Color(0xFF071325)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName.isEmpty
                              ? 'Booking Details'
                              : booking.serviceName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _formatLabel(booking.status),
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          label: 'Client',
                          value: booking.clientName,
                        ),
                        _buildInfoRow(
                          label: 'Date',
                          value: _formatDate(booking.selectedDate),
                        ),
                        _buildInfoRow(
                          label: 'Time',
                          value: booking.selectedTime,
                        ),
                        // Address privacy protection rule
                        _buildInfoRow(
                          label: 'Address',
                          value: isAcceptedOrCompleted
                              ? booking.address
                              : 'Hidden until accepted (Privacy Protected)',
                          isHidden: !isAcceptedOrCompleted,
                        ),
                        _buildInfoRow(
                          label: 'Notes',
                          value: booking.notes,
                        ),
                        if (booking.status.toLowerCase() == 'cancelled' &&
                            (booking.cancelReason ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Reason the client cancelled',
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  booking.cancelReason!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (booking.rescheduleHistory.isNotEmpty &&
                            (booking.status.toLowerCase() == 'pending' ||
                                booking.status.toLowerCase() == 'accepted')) ...[
                          const SizedBox(height: 16),
                          Builder(builder: (context) {
                            final latest = booking.rescheduleHistory.last;
                            final by = (latest['rescheduledBy'] ?? '').toString();
                            final reason = (latest['reason'] ?? '').toString();

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.event_repeat_rounded,
                                          color: Color(0xFF38BDF8), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rescheduled by ${by == 'provider' ? 'you' : 'the client'}',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF38BDF8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'From ${latest['oldDate']} ${latest['oldTime']}  \u2192  ${latest['newDate']} ${latest['newTime']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      reason,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  if (isAcceptedOrCompleted) ...[
                    const SizedBox(height: 24),
                    ProgressTimeline(
                      bookingId: booking.id,
                      providerId: booking.providerId,
                      showAddButton: booking.status.toLowerCase() == 'accepted',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}