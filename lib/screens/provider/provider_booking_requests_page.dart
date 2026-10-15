import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking_request_card.dart';

class ProviderBookingRequestsPage extends StatelessWidget {
  final String providerId;

  const ProviderBookingRequestsPage({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
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
                                'Booking Requests',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage pending client appointments',
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

                  // --- BOOKINGS STREAM BUILDER ---
                  Expanded(
                    child: StreamBuilder<List<BookingModel>>(
                      stream: bookingService.getPendingBookings(providerId),
                      builder: (context, snapshot) {
                        // Show loading indicator while fetching data
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF38BDF8),
                            ),
                          );
                        }

                        // Show error message if something goes wrong
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading bookings',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 13.5,
                              ),
                            ),
                          );
                        }

                        final bookings = snapshot.data ?? [];

                        // Show message if no pending bookings
                        if (bookings.isEmpty) {
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
                                    Icons.event_available_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No pending booking requests',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'New requests will appear here',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Display list of bookings
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: BookingRequestCard(
                                booking: booking,
                                onAccept: () async {
                                  await bookingService.updateBookingStatus(
                                    bookingId: booking.id,
                                    newStatus: 'accepted',
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Booking accepted'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                },
                                onReject: () async {
                                  await bookingService.updateBookingStatus(
                                    bookingId: booking.id,
                                    newStatus: 'rejected',
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Booking rejected'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
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