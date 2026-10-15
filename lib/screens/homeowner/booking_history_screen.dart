import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/rate_review_widgets.dart';

class HomeownerBookingHistoryScreen extends StatelessWidget {
  const HomeownerBookingHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF38BDF8);
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Booking History',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
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
              child: user == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('homeownerId', isEqualTo: user.uid)
                          .snapshots(),
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
                            final aData = a.data();
                            final bData = b.data();
                            DateTime pick(Map<String, dynamic> d) {
                              final ts = d['completedAt'] ??
                                  d['updatedAt'] ??
                                  d['createdAt'];
                              return ts is Timestamp
                                  ? ts.toDate()
                                  : DateTime.fromMillisecondsSinceEpoch(0);
                            }
                            return pick(bData).compareTo(pick(aData));
                          });

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings yet.',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final bookingId = doc.id;

                            final service = _capitalize(
                                (data['service'] ?? 'Service').toString());

                            final providerId =
                                (data['providerId'] ?? '').toString();
                            final providerName = _capitalize(
                                (data['providerName'] ?? 'Provider')
                                    .toString());
                            final providerPic =
                                (data['providerProfilePic'] ?? data['providerPic'])
                                    ?.toString();

                            final status =
                                (data['status'] ?? 'pending').toString();
                            final isCompleted =
                                status.toLowerCase() == 'completed';
                            final isRated = data['rated'] == true;
                            final ratingGiven = data['ratingGiven'];
                            final ratingComment =
                                (data['ratingComment'] ?? '').toString();

                            final ts = data['completedAt'] ??
                                data['updatedAt'] ??
                                data['createdAt'];
                            final displayDate = ts is Timestamp
                                ? _formatDate(ts.toDate())
                                : '';
                            final color = _statusColor(status);

                            return Container(
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
                                  color: color.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.18),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
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
                                          service,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: color,
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
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          color: const Color(0xFF0EA5E9)
                                              .withValues(alpha: 0.2),
                                          child: providerPic != null &&
                                                  providerPic.isNotEmpty
                                              ? Image.network(
                                                  providerPic,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      _buildAvatarFallback(
                                                          providerName),
                                                )
                                              : _buildAvatarFallback(
                                                  providerName),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              providerName,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              displayDate,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isCompleted) ...[
                                    const SizedBox(height: 16),
                                    if (isRated && ratingGiven != null) ...[
                                      Row(
                                        children: [
                                          StarRatingDisplay(
                                              rating: (ratingGiven as num)
                                                  .toDouble(),
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$ratingGiven/5',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFFF59E0B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (ratingComment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '"$ratingComment"',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white
                                                .withValues(alpha: 0.75),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ] else
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            showRateReviewDialog(
                                              context: context,
                                              bookingId: bookingId,
                                              homeownerId: user.uid,
                                              homeownerName: user.displayName ??
                                                  'Homeowner',
                                              providerId: providerId,
                                              providerName: providerName,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFF59E0B),
                                              width: 1.5,
                                            ),
                                            foregroundColor:
                                                const Color(0xFFF59E0B),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            backgroundColor: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.05),
                                          ),
                                          icon: const Icon(Icons.star_rounded,
                                              size: 16),
                                          label: Text(
                                            'Rate this Service',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
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
          ),
        ],
      ),
    );
  }
}