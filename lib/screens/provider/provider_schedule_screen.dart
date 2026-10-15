import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/provider_schedule_service.dart';
import '../../widgets/booking_action_dialogs.dart';
import '../../widgets/provider_bottom_nav_bar.dart';
import 'provider_booking_details_screen.dart';

class ProviderScheduleScreen extends StatefulWidget {
  const ProviderScheduleScreen({super.key});

  @override
  State<ProviderScheduleScreen> createState() =>
      _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends State<ProviderScheduleScreen> {
  final ProviderScheduleService _service = ProviderScheduleService();
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 2),
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
                              'SCHEDULE & OPERATIONS',
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
                          'My Schedule',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your bookings and service schedule',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- SCHEDULE LIST FEED ---
                  Expanded(
                    child: StreamBuilder<List<BookingModel>>(
                      stream: _service.getProviderBookings(providerId),
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

                        final schedules = snapshot.data ?? [];

                        if (schedules.isEmpty) {
                          return _buildEmptyRefresh();
                        }

                        final now = DateTime.now();
                        final todayStart =
                            DateTime(now.year, now.month, now.day);
                        final tomorrowStart =
                            todayStart.add(const Duration(days: 1));

                        final List<BookingModel> today = [];
                        final List<BookingModel> upcoming = [];
                        final List<BookingModel> completed = [];

                        for (final booking in schedules) {
                          final status = booking.status.toLowerCase();

                          if (status == 'completed' ||
                              status == 'rejected' ||
                              status == 'cancelled') {
                            final finishedAt =
                                booking.completedAt ?? booking.updatedAt;
                            final isThisMonth =
                                finishedAt.year == now.year &&
                                    finishedAt.month == now.month;

                            if (isThisMonth) {
                              completed.add(booking);
                            }
                            continue;
                          }

                          final date = booking.createdAt;
                          final normalized =
                              DateTime(date.year, date.month, date.day);

                          if (normalized.isBefore(todayStart)) {
                            today.add(booking);
                          } else if (normalized.isBefore(tomorrowStart)) {
                            today.add(booking);
                          } else {
                            upcoming.add(booking);
                          }
                        }

                        return RefreshIndicator(
                          color: const Color(0xFF38BDF8),
                          backgroundColor: const Color(0xFF0F172A),
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              if (today.isNotEmpty) ...[
                                _buildSection('Today', today),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              if (upcoming.isNotEmpty) ...[
                                _buildSection('Upcoming', upcoming),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              if (completed.isNotEmpty)
                                _buildSection('Completed', completed),
                            ],
                          ),
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

  Future<void> _refresh() async {
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _handleBookingAction({
    required BookingModel booking,
    required String newStatus,
  }) async {
    final actionLabel = newStatus == 'accepted' ? 'accept' : 'reject';

    final confirmed = await _showStatusConfirmDialog(
      actionLabel: actionLabel,
      booking: booking,
    );

    if (confirmed != true) return;

    try {
      await _bookingService.updateBookingStatus(
        bookingId: booking.id,
        newStatus: newStatus,
      );

      if (!mounted) return;

      final successText = newStatus == 'accepted'
          ? 'Booking accepted successfully.'
          : 'Booking rejected successfully.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successText),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<bool?> _showStatusConfirmDialog({
    required String actionLabel,
    required BookingModel booking,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          title: Text(
            '${_capitalize(actionLabel)} Booking',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to $actionLabel this booking for ${booking.clientName}?',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionLabel == 'accept'
                    ? const Color(0xFF0284C7)
                    : const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _capitalize(actionLabel),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyRefresh() {
    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0F172A),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 120),
          _EmptyScheduleState(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<BookingModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                list.length.toString(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: list
              .map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildCard(booking),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCard(BookingModel booking) {
    final status = booking.status.toLowerCase();
    final isPending = status == 'pending';

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderBookingDetailsScreen(
                  booking: booking,
                ),
              ),
            );

            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Client: ${booking.clientName}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDate(booking.createdAt)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () async {
                              final success = await showDeclineBookingDialog(
                                context: context,
                                bookingId: booking.id,
                                serviceName: booking.service,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking declined.'),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                                setState(() {});
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFEF4444),
                                width: 1.2,
                              ),
                              foregroundColor: const Color(0xFFEF4444),
                              backgroundColor:
                                  const Color(0xFFEF4444).withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              _handleBookingAction(
                                booking: booking,
                                newStatus: 'accepted',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                if (status == 'pending' || status == 'accepted') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await showRescheduleBookingDialog(
                          context: context,
                          bookingId: booking.id,
                          serviceName: booking.service,
                          rescheduledBy: 'provider',
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking rescheduled.'),
                              backgroundColor: Color(0xFF38BDF8),
                            ),
                          );
                          setState(() {});
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                            width: 1.2),
                        foregroundColor: const Color(0xFF38BDF8),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.event_repeat_rounded, size: 16),
                      label: Text('Reschedule',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();

    Color bgColor = Colors.white.withValues(alpha: 0.05);
    Color textColor = Colors.white70;
    String label = status;

    if (s == 'pending') {
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      textColor = const Color(0xFFF59E0B);
      label = 'Pending';
    } else if (s == 'accepted') {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.2);
      textColor = const Color(0xFF10B981);
      label = 'Accepted';
    } else if (s == 'completed') {
      bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.2);
      textColor = const Color(0xFF38BDF8);
      label = 'Completed';
    } else if (s == 'rejected') {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
      textColor = const Color(0xFFEF4444);
      label = 'Rejected';
    } else if (s == 'cancelled') {
      bgColor = Colors.white.withValues(alpha: 0.08);
      textColor = Colors.white54;
      label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}