import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/progress_timeline.dart';

/// Lets an admin see exactly what the homeowner sees for a booking: the
/// provider's day-by-day photo progress log.
class AdminBookingProgressScreen extends StatelessWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String homeownerName;
  final String service;
  final String status;

  const AdminBookingProgressScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.homeownerName,
    required this.service,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Booking Progress',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Homeowner: $homeownerName',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      'Provider: $providerName',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $status',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ProgressTimeline(
                bookingId: bookingId,
                providerId: providerId,
                showAddButton: false,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}