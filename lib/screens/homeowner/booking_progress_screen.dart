import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/report_service.dart';
import '../../widgets/progress_timeline.dart';

class BookingProgressScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String service;
  final String status;

  const BookingProgressScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.status,
  });

  @override
  State<BookingProgressScreen> createState() => _BookingProgressScreenState();
}

class _BookingProgressScreenState extends State<BookingProgressScreen> {
  final ReportService _reportService = ReportService();

  final List<String> _reasons = const [
    'No-show / did not arrive',
    'Poor quality of work',
    'Unsafe or unprofessional behavior',
    'Overcharging / payment issue',
    'Other',
  ];

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _openReportDialog() async {
    String selectedReason = _reasons.first;
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              setDialogState(() => isSubmitting = true);

              try {
                await _reportService.submitReport(
                  bookingId: widget.bookingId,
                  homeownerId: user.uid,
                  homeownerName: user.displayName ?? 'Homeowner',
                  providerId: widget.providerId,
                  providerName: widget.providerName,
                  reason: selectedReason,
                  description: descriptionController.text,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Report submitted. Our admin team will review it.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to submit report: $e')),
                  );
                }
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              title: Text(
                'Report ${widget.providerName}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Reason',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_reasons.map((reason) => RadioListTile<String>(
                          value: reason,
                          // ignore: deprecated_member_use
                          groupValue: selectedReason,
                          // ignore: deprecated_member_use
                          onChanged: (val) =>
                              setDialogState(() => selectedReason = val!),
                          activeColor: const Color(0xFF38BDF8),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            reason,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ))),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.white60, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF030712),
                  Color(0xFF0B132B),
                  Color(0xFF030712),
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
                  // Elite Provider Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: widget.providerId.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection('providers')
                                  .doc(widget.providerId)
                                  .snapshots()
                              : null,
                          builder: (context, providerSnapshot) {
                            String? profilePic;
                            if (providerSnapshot.hasData &&
                                providerSnapshot.data != null &&
                                providerSnapshot.data!.exists) {
                              final pData = providerSnapshot.data!.data();
                              profilePic =
                                  pData?['profileImageUrl'] ?? pData?['photoUrl'];
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                child: profilePic != null && profilePic.isNotEmpty
                                    ? (profilePic.startsWith('data:image')
                                        ? Image.memory(
                                            base64Decode(profilePic.split(',').last),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _buildAvatarFallback(
                                                    widget.providerName),
                                          )
                                        : Image.network(
                                            profilePic,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _buildAvatarFallback(
                                                    widget.providerName),
                                          ))
                                    : _buildAvatarFallback(widget.providerName),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.service,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Provider: ${widget.providerName}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${widget.status[0].toUpperCase()}${widget.status.substring(1)}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rejected / Cancelled Reason Box
                  if (widget.status.toLowerCase() == 'rejected' ||
                      widget.status.toLowerCase() == 'cancelled')
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(widget.bookingId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final isRejected = widget.status.toLowerCase() == 'rejected';
                        final reason = isRejected
                            ? (data?['declineReason'] ?? '').toString()
                            : (data?['cancelReason'] ?? '').toString();

                        if (reason.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      isRejected
                                          ? 'Reason the provider declined'
                                          : 'Reason you cancelled',
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reason,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Reschedule History Box
                  if (widget.status.toLowerCase() == 'pending' ||
                      widget.status.toLowerCase() == 'accepted')
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(widget.bookingId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final history = snapshot.data?.data()?['rescheduleHistory']
                            as List<dynamic>?;
                        if (history == null || history.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final latest =
                            Map<String, dynamic>.from(history.last as Map);
                        final by = (latest['rescheduledBy'] ?? '').toString();
                        final reason = (latest['reason'] ?? '').toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_repeat_rounded,
                                        color: Color(0xFF38BDF8), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rescheduled by ${by == 'homeowner' ? 'you' : 'the provider'}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From ${latest['oldDate']} ${latest['oldTime']}  \u2192  ${latest['newDate']} ${latest['newTime']}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (reason.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    reason,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  ProgressTimeline(
                    bookingId: widget.bookingId,
                    providerId: widget.providerId,
                    showAddButton: false,
                  ),
                  const SizedBox(height: 24),

                  // Report Provider Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _openReportDialog,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.06),
                      ),
                      icon: const Icon(Icons.flag_rounded, size: 18),
                      label: Text(
                        'Report Provider',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}