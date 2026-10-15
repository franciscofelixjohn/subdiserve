import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/report_service.dart';
import '../../widgets/suspension_dialogs.dart';

/// Lets an admin manage a booking: review any reports the homeowner has
/// filed against the provider for this job, and take action (mark as
/// reviewed/resolved, or suspend the provider's account).
class AdminBookingManageScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String homeownerName;
  final String service;

  const AdminBookingManageScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.homeownerName,
    required this.service,
  });

  @override
  State<AdminBookingManageScreen> createState() =>
      _AdminBookingManageScreenState();
}

class _AdminBookingManageScreenState extends State<AdminBookingManageScreen> {
  final ReportService _reportService = ReportService();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return const Color(0xFF38BDF8);
      case 'resolved':
        return const Color(0xFF10B981);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Manage Booking',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.providerId)
                    .snapshots(),
                builder: (context, providerSnapshot) {
                  final providerData = providerSnapshot.data?.data() ?? {};
                  final providerStatus =
                      (providerData['status'] ?? 'Active').toString();
                  final isSuspended = providerStatus == 'Suspended' ||
                      providerStatus == 'Restricted';
                  final suspensionReason =
                      (providerData['suspensionReason'] ?? '').toString();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.service,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.homeownerName} \u2194 ${widget.providerName}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (isSuspended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (providerStatus == 'Suspended'
                                          ? Colors.redAccent
                                          : Colors.orangeAccent)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(providerStatus,
                                    style: GoogleFonts.poppins(
                                        color: providerStatus == 'Suspended'
                                            ? Colors.redAccent
                                            : Colors.orangeAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        if (isSuspended && suspensionReason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: $suspensionReason',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: providerStatus == 'Restricted'
                                    ? ElevatedButton(
                                        onPressed: () => showActivateAccountDialog(
                                          context: context,
                                          userId: widget.providerId,
                                          userName: widget.providerName,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Unrestrict',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      )
                                    : OutlinedButton(
                                        onPressed: providerStatus == 'Suspended'
                                            ? null
                                            : () => showRestrictAccountDialog(
                                                  context: context,
                                                  userId: widget.providerId,
                                                  userName: widget.providerName,
                                                ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.orangeAccent),
                                          foregroundColor: Colors.orangeAccent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Restrict',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: providerStatus == 'Suspended'
                                    ? ElevatedButton(
                                        onPressed: () => showActivateAccountDialog(
                                          context: context,
                                          userId: widget.providerId,
                                          userName: widget.providerName,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Activate',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      )
                                    : OutlinedButton(
                                        onPressed: () => showSuspendAccountDialog(
                                          context: context,
                                          userId: widget.providerId,
                                          userName: widget.providerName,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.redAccent),
                                          foregroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Suspend Provider',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => showAppealHistoryDialog(
                              context: context,
                              userId: widget.providerId,
                              userName: widget.providerName,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2)),
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Appeal History',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Homeowner Reports',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Reports filed by the homeowner about this booking/provider.',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _reportService
                      .streamReportsForBooking(widget.bookingId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF38BDF8)),
                      );
                    }

                    final docs = (snapshot.data?.docs ?? []).toList()
                      ..sort((a, b) {
                        final aTs = a.data()['createdAt'];
                        final bTs = b.data()['createdAt'];
                        final aDate = aTs is Timestamp
                            ? aTs.toDate()
                            : DateTime.fromMillisecondsSinceEpoch(0);
                        final bDate = bTs is Timestamp
                            ? bTs.toDate()
                            : DateTime.fromMillisecondsSinceEpoch(0);
                        return bDate.compareTo(aDate); // newest first
                      });

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No reports filed for this booking.',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 12),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final reportDoc = docs[index];
                        final data = reportDoc.data();
                        final status = (data['status'] ?? 'pending').toString();
                        final reason = (data['reason'] ?? '').toString();
                        final description =
                            (data['description'] ?? '').toString();
                        final homeownerName =
                            (data['homeownerName'] ?? 'Homeowner').toString();
                        final color = _statusColor(status);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Filed by: $homeownerName',
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 11),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (status.toLowerCase() == 'pending')
                                    Expanded(
                                      child: SizedBox(
                                        height: 30,
                                        child: OutlinedButton(
                                          onPressed: () => _reportService
                                              .updateReportStatus(
                                            reportId: reportDoc.id,
                                            status: 'reviewed',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Color(0xFF38BDF8)),
                                            foregroundColor:
                                                const Color(0xFF38BDF8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          child: Text('Mark Reviewed',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11)),
                                        ),
                                      ),
                                    ),
                                  if (status.toLowerCase() != 'resolved') ...[
                                    if (status.toLowerCase() == 'pending')
                                      const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: () => _reportService
                                              .updateReportStatus(
                                            reportId: reportDoc.id,
                                            status: 'resolved',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          child: Text('Mark Resolved',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}