import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/bottom_nav_bar.dart';
import '../chat/chat_screen.dart';
import 'booking_progress_screen.dart';

class ActiveBookingsScreen extends StatelessWidget {
  const ActiveBookingsScreen({super.key});

  // Returns color based on booking status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'completed':
        return const Color(0xFF38BDF8);
      case 'cancelled':
        return Colors.white54;
      default:
        return Colors.white70;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: Center(
          child: Text(
            'No logged-in user found.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
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
                  // --- ELITE TOP HEADER CARD (LUXURY STYLE) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SCHEDULE & TRACKING',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'My Appointments',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Track active bookings & history',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .where('homeownerId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final allDocs = snapshot.data?.docs ?? [];
                            if (allDocs.isEmpty) return const SizedBox.shrink();
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullBookingsHistoryScreen(userId: user.uid),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'See All (${allDocs.length})',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- BOOKINGS LIST FEED ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('homeownerId', isEqualTo: user.uid)
                          .snapshots(),
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
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.poppins(color: Colors.redAccent),
                            ),
                          );
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        final now = DateTime.now();

                        final docs = allDocs.where((doc) {
                          final data = doc.data();
                          final status = (data['status'] ?? 'pending').toString().toLowerCase();

                          if (status == 'completed' ||
                              status == 'rejected' ||
                              status == 'cancelled') {
                            final completedTs = data['completedAt'];
                            final updatedTs = data['updatedAt'];
                            DateTime? finishedAt;
                            if (completedTs is Timestamp) {
                              finishedAt = completedTs.toDate();
                            } else if (updatedTs is Timestamp) {
                              finishedAt = updatedTs.toDate();
                            }
                            if (finishedAt == null) return true;
                            return finishedAt.year == now.year &&
                                finishedAt.month == now.month;
                          }
                          return true;
                        }).toList();

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
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No active bookings found.',
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

                        final sortedBookings = docs.toList()
                          ..sort((a, b) {
                            final aData = a.data();
                            final bData = b.data();
                            final aTimestamp = aData['selectedDate'];
                            final bTimestamp = bData['selectedDate'];

                            DateTime aDate = DateTime.fromMillisecondsSinceEpoch(0);
                            DateTime bDate = DateTime.fromMillisecondsSinceEpoch(0);

                            if (aTimestamp is Timestamp) aDate = aTimestamp.toDate();
                            if (bTimestamp is Timestamp) bDate = bTimestamp.toDate();
                            return bDate.compareTo(aDate);
                          });

                        final recentBookings = sortedBookings.take(5).toList();

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentBookings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final bookingDoc = recentBookings[index];
                            final booking = bookingDoc.data();
                            final String bookingId = bookingDoc.id;

                            final String providerId = (booking['providerId'] ?? '').toString();
                            final String providerName = (booking['providerName'] ?? 'Unknown Provider').toString();
                            final String service = (booking['service'] ?? 'Unknown Service').toString();
                            final String date = (booking['bookingDate'] ?? 'No Date').toString();
                            final String time = (booking['bookingTime'] ?? 'No Time').toString();
                            final String status = (booking['status'] ?? 'pending').toString();

                            final Color statusColor = _getStatusColor(status);

                            return BookingCardItem(
                              bookingId: bookingId,
                              providerId: providerId,
                              providerName: providerName,
                              service: service,
                              date: date,
                              time: time,
                              status: status,
                              statusColor: statusColor,
                              buildAvatarFallback: _buildAvatarFallback,
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

class BookingCardItem extends StatelessWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String service;
  final String date;
  final String time;
  final String status;
  final Color statusColor;
  final Widget Function(String) buildAvatarFallback;

  const BookingCardItem({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.date,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.buildAvatarFallback,
  });

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'PENDING';
      case 'accepted': return 'ACCEPTED';
      case 'rejected': return 'REJECTED';
      case 'completed': return 'COMPLETED';
      case 'cancelled': return 'CANCELLED';
      default: return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: providerId.isNotEmpty
                      ? FirebaseFirestore.instance.collection('providers').doc(providerId).snapshots()
                      : null,
                  builder: (context, providerSnapshot) {
                    String? providerProfilePic;
                    if (providerSnapshot.hasData && providerSnapshot.data != null && providerSnapshot.data!.exists) {
                      final pData = providerSnapshot.data!.data();
                      providerProfilePic = pData?['profileImageUrl'] ?? pData?['photoUrl'];
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: providerProfilePic != null && providerProfilePic.isNotEmpty
                            ? (providerProfilePic.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(providerProfilePic.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => buildAvatarFallback(providerName),
                                  )
                                : Image.network(
                                    providerProfilePic,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => buildAvatarFallback(providerName),
                                  ))
                            : buildAvatarFallback(providerName),
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
                        providerName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _getStatusLabel(status),
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
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(date, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(time, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingProgressScreen(
                              bookingId: bookingId,
                              providerId: providerId,
                              providerName: providerName,
                              service: service,
                              status: status,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: Text('Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: providerId,
                              otherUserName: providerName,
                              bookingId: bookingId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Message', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullBookingsHistoryScreen extends StatelessWidget {
  final String userId;

  const FullBookingsHistoryScreen({super.key, required this.userId});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'accepted': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      case 'completed': return const Color(0xFF38BDF8);
      case 'cancelled': return Colors.white54;
      default: return Colors.white70;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'All Bookings History',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
                colors: [Color(0xFF030712), Color(0xFF0B132B), Color(0xFF030712)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('homeownerId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                }
                final bookings = snapshot.data?.docs ?? [];
                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      'No booking history found.',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final bookingDoc = bookings[index];
                    final booking = bookingDoc.data();
                    final String bookingId = bookingDoc.id;

                    final String providerId = (booking['providerId'] ?? '').toString();
                    final String providerName = (booking['providerName'] ?? 'Unknown Provider').toString();
                    final String service = (booking['service'] ?? 'Unknown Service').toString();
                    final String date = (booking['bookingDate'] ?? 'No Date').toString();
                    final String time = (booking['bookingTime'] ?? 'No Time').toString();
                    final String status = (booking['status'] ?? 'pending').toString();

                    final Color statusColor = _getStatusColor(status);

                    return BookingCardItem(
                      bookingId: bookingId,
                      providerId: providerId,
                      providerName: providerName,
                      service: service,
                      date: date,
                      time: time,
                      status: status,
                      statusColor: statusColor,
                      buildAvatarFallback: _buildAvatarFallback,
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