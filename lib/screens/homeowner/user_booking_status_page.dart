import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../chat/chat_screen.dart';

class UserBookingStatusPage extends StatefulWidget {
  final String? userId;

  const UserBookingStatusPage({
    super.key,
    this.userId,
  });

  @override
  State<UserBookingStatusPage> createState() => _UserBookingStatusPageState();
}

class _UserBookingStatusPageState extends State<UserBookingStatusPage> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return Colors.redAccent;
      case 'completed':
        return const Color(0xFF38BDF8);
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'rejected':
        return 'REJECTED';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  // ✅ Dynamic Category Icons para sa bawat Booking Card
  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electric')) return Icons.bolt_rounded;
    if (lower.contains('carpenter') || lower.contains('wood')) return Icons.handyman_rounded;
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('aircon')) return Icons.ac_unit_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('computer') || lower.contains('repair')) return Icons.computer_rounded;
    return Icons.home_repair_service_rounded;
  }

  // ✅ Modern Rating & Report Dialog (1 to 5 Stars + Optional Message)
  void _showReportOrRateDialog(BookingModel booking) {
    final TextEditingController commentController = TextEditingController();
    double rating = 5.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0B192C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          title: Text(
            'Rate Service Provider',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider: ${booking.providerName} (${booking.providerCategory})',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tap stars to rate',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Feedback / Message (Optional):',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this service...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF38BDF8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final comment = commentController.text.trim();
                      setDialogState(() => isSubmitting = true);

                      try {
                        final bookingService = BookingService();
                        await bookingService.submitBookingRating(
                          bookingId: booking.id,
                          providerId: booking.providerId,
                          providerCategory: booking.providerCategory,
                          rating: rating,
                          comment: comment.isEmpty ? 'No comment provided' : comment,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rating submitted successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Rating',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeUserId = widget.userId ?? currentUser?.uid;

    if (activeUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        backgroundColor: Color(0xFF020408),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020408),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'My Bookings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          StreamBuilder<List<BookingModel>>(
            stream: bookingService.getUserBookings(activeUserId),
            builder: (context, snapshot) {
              final allBookings = snapshot.data ?? [];
              if (allBookings.length > 5) {
                return TextButton(
                  onPressed: () {
                    // Navigate to Full History Screen kung gusto makita lahat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullBookingsHistoryScreen(userId: activeUserId),
                      ),
                    );
                  },
                  child: Text(
                    'See All (${allBookings.length})',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingService.getUserBookings(activeUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF38BDF8),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load bookings.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                final allBookings = snapshot.data ?? [];

                if (allBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF38BDF8),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings yet',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your scheduled services will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ✅ I-limit muna sa huling 5 recent bookings ang ipakita sa main screen
                final recentBookings = allBookings.take(5).toList();

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: recentBookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = recentBookings[index];
                    final statusColor = _getStatusColor(booking.status);
                    final isCompleted = booking.status.toLowerCase() == 'completed';
                    final categoryIcon = _getCategoryIcon(booking.providerCategory);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0C2340), Color(0xFF071325)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(categoryIcon, color: const Color(0xFF38BDF8), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.providerName,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.providerCategory,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  _getStatusLabel(booking.status),
                                  style: GoogleFonts.poppins(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 10),
                          Text(
                            'Service: ${booking.service}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${booking.bookingDate} • ${booking.bookingTime}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          otherUserId: booking.providerId,
                                          otherUserName: booking.providerName,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                                  label: Text(
                                    'Message',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF38BDF8),
                                    side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showReportOrRateDialog(booking),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                      foregroundColor: const Color(0xFF38BDF8),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.star_rate_rounded, size: 14),
                                    label: Text(
                                      'Rate Provider',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
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
    );
  }
}

// ✅ Dedicated Screen para sa "See All" Bookings History
class FullBookingsHistoryScreen extends StatelessWidget {
  final String userId;

  const FullBookingsHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020408),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'All Bookings History',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getUserBookings(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
          }
          final bookings = snapshot.data ?? [];
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.providerName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${booking.service} • ${booking.bookingDate}', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}