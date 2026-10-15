import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../services/provider_schedule_service.dart';
import '../../widgets/rate_review_widgets.dart';

/// Shows a provider's FULL, all-time job history (completed + cancelled),
/// each with the homeowner's rating and comment if one was given. Unlike
/// "My Schedule" (which only shows the current month's completed jobs),
/// this screen is the permanent record.
class ProviderJobHistoryScreen extends StatelessWidget {
  const ProviderJobHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                                    'PERMANENT RECORD',
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
                                'Job History & Ratings',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'All-time completed & feedback records',
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

                  // --- STREAM BUILDER HISTORY LIST ---
                  Expanded(
                    child: StreamBuilder<List<BookingModel>>(
                      stream: ProviderScheduleService().getProviderBookings(providerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                          );
                        }

                        final all = snapshot.data ?? [];
                        final history = all
                            .where((b) =>
                                b.status == 'completed' ||
                                b.status == 'cancelled' ||
                                b.status == 'rejected')
                            .toList()
                          ..sort((a, b) {
                            final aDate = a.completedAt ?? a.updatedAt;
                            final bDate = b.completedAt ?? b.updatedAt;
                            return bDate.compareTo(aDate); // newest first
                          });

                        if (history.isEmpty) {
                          return Center(
                            child: Text(
                              'No completed or cancelled jobs yet.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 13.5),
                            ),
                          );
                        }

                        final completedCount =
                            history.where((b) => b.status == 'completed').length;

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: history.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$completedCount completed • ${history.length - completedCount} cancelled/rejected',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w500),
                                ),
                              );
                            }

                            final booking = history[index - 1];
                            final isCompleted = booking.status == 'completed';
                            final statusColor =
                                isCompleted ? const Color(0xFF10B981) : Colors.redAccent;
                            final displayDate = booking.completedAt ?? booking.updatedAt;

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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking.service,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                              color: statusColor.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          isCompleted ? 'COMPLETED' : booking.status.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Client: ${booking.homeownerName}  •  ${_formatDate(displayDate)}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                  if (isCompleted) ...[
                                    const SizedBox(height: 12),
                                    if (booking.rated && booking.ratingGiven != null) ...[
                                      Row(
                                        children: [
                                          StarRatingDisplay(
                                              rating: booking.ratingGiven!.toDouble(),
                                              size: 14),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${booking.ratingGiven}/5',
                                            style: GoogleFonts.poppins(
                                                color: const Color(0xFFF59E0B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      if ((booking.ratingComment ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '"${booking.ratingComment}"',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ] else
                                      Text(
                                        'Not yet rated by the homeowner.',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic),
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