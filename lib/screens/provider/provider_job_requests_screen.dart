import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/provider_bottom_nav_bar.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  Future<void> updateBookingStatus(
    BuildContext context,
    String bookingId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': newStatus,
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking marked as $newStatus'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 2),
      body: Stack(
        children: [
          // 1. Ambient Glow Background
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
          // 2. Deep Obsidian Luxury Gradient Background
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ELITE TOP HEADER CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
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
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (Navigator.canPop(context)) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Color(0xFF38BDF8), size: 20),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                          blurRadius: 6,
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'APPOINTMENTS',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF38BDF8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Job Requests',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review and manage incoming client appointments',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- STREAM BUILDER ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF38BDF8),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: Color(0xFF38BDF8),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No job requests.',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Incoming bookings will appear here.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bookings = snapshot.data!.docs;

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final doc = bookings[index];
                            final bookingId = doc.id;
                            final data = doc.data() as Map<String, dynamic>;

                            final service = data['serviceName'] ?? '';
                            final date = data['selectedDate'] ?? '';
                            final time = data['selectedTime'] ?? '';
                            final address = data['address'] ?? '';
                            final status = data['status'] ?? 'Pending';
                            final providerName = data['providerName'] ?? '';

                            Color statusColor = const Color(0xFFF59E0B);
                            if (status == 'Confirmed') {
                              statusColor = const Color(0xFF38BDF8);
                            }
                            if (status == 'Completed') {
                              statusColor = const Color(0xFF10B981);
                            }
                            if (status == 'Rejected') {
                              statusColor = const Color(0xFFEF4444);
                            }

                            // --- FROSTED GLASS CONTAINER CARD ---
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
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
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.handyman_rounded,
                                          color: Color(0xFF38BDF8),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              address,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Provider: $providerName',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF38BDF8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: statusColor
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.poppins(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        date.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        time,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (status == 'Pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 42,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  updateBookingStatus(
                                                context,
                                                bookingId,
                                                'Rejected',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: Color(0xFFEF4444),
                                                  width: 1.2,
                                                ),
                                                foregroundColor:
                                                    const Color(0xFFEF4444),
                                                backgroundColor:
                                                    const Color(0xFFEF4444)
                                                        .withValues(
                                                            alpha: 0.08),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14),
                                                ),
                                              ),
                                              child: Text(
                                                'Reject',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 42,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  updateBookingStatus(
                                                context,
                                                bookingId,
                                                'Confirmed',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF0284C7),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14),
                                                ),
                                              ),
                                              child: Text(
                                                'Accept',
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
        ],
      ),
    );
  }
}