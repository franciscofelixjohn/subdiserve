import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/booking_model.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../homeowner/booking_progress_screen.dart';
import '../provider/provider_booking_details_screen.dart';
import '../provider/provider_portfolio_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color _background = Color(0xFF020408);
  static const Color _panel = Color(0xFF0C2340);
  static const Color _blue = Color(0xFF38BDF8);

  Future<void> _showMessage(BuildContext context, String message) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _panel));
  }

  Future<void> _showDetails(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B192C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message.isNotEmpty ? message : 'No additional details available.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: _blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccountNotification(
    BuildContext context,
    NotificationModel notification,
    String userId,
  ) async {
    String adminNote = '';
    String status = '';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? <String, dynamic>{};

      status = (userData['status'] ?? '').toString();

      final title = notification.title.toLowerCase();

      if (title.contains('reactivat')) {
        adminNote = (userData['lastActivationNote'] ?? '').toString().trim();

        if (adminNote.isEmpty) {
          final marker = 'Note:';
          final index = notification.body.indexOf(marker);

          if (index >= 0) {
            adminNote = notification.body
                .substring(index + marker.length)
                .trim();
          } else {
            adminNote = notification.body;
          }
        }
      } else {
        adminNote = (userData['suspensionReason'] ?? '').toString().trim();

        if (adminNote.isEmpty) {
          adminNote = notification.body;
        }
      }
    } catch (_) {
      adminNote = notification.body;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B192C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined, color: _blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.title.toLowerCase().contains('reactivat')
                    ? 'Message from the administrator'
                    : 'Administrator note / reason',
                style: GoogleFonts.poppins(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  adminNote.isNotEmpty
                      ? adminNote
                      : 'No administrator note was provided.',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Account status: $status',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                notification.body,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: _blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBooking(
    BuildContext context,
    String userId,
    String bookingId,
  ) async {
    if (bookingId.isEmpty) {
      await _showMessage(
        context,
        'This notification has no booking reference. Open your Bookings page to find it.',
      );
      return;
    }

    final bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (!context.mounted) return;

    if (!bookingDoc.exists) {
      await _showMessage(context, 'The related booking could not be found.');
      return;
    }

    final booking = BookingModel.fromFirestore(bookingDoc);

    if (booking.homeownerId != userId && booking.providerId != userId) {
      await _showMessage(
        context,
        'You do not have permission to view this booking.',
      );
      return;
    }

    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(userId)
        .get();

    if (!context.mounted) return;

    if (providerDoc.exists && booking.providerId == userId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderBookingDetailsScreen(booking: booking),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingProgressScreen(
            bookingId: booking.id,
            providerId: booking.providerId,
            providerName: booking.providerName,
            service: booking.service,
            status: booking.status,
          ),
        ),
      );
    }
  }

  Future<void> _openPostNotification(
    BuildContext context,
    NotificationModel notification,
    String userId,
    Map<String, dynamic> data,
  ) async {
    final postId = (data['postId'] ?? '').toString().trim();

    // Check whether this account is a service provider.
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(userId)
        .get();

    if (!context.mounted) return;

    if (providerDoc.exists) {
      // New notifications have a postId. Verify it before opening the portfolio.
      if (postId.isNotEmpty) {
        final postDoc = await FirebaseFirestore.instance
            .collection('provider_posts')
            .doc(postId)
            .get();

        if (!context.mounted) return;

        if (!postDoc.exists) {
          // A deleted post must not prevent the user from opening the portfolio.
          await _showMessage(
            context,
            'The original post is no longer available. Opening your portfolio instead.',
          );
          if (!context.mounted) return;
        }
      }

      // Also works for older notifications that do not have postId.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderPortfolioScreen()),
      );

      return;
    }

    // If the recipient is a homeowner, show the related post details.
    if (postId.isEmpty) {
      await _showDetails(context, notification.title, notification.body);
      return;
    }

    final postDoc = await FirebaseFirestore.instance
        .collection('provider_posts')
        .doc(postId)
        .get();

    if (!context.mounted) return;

    if (!postDoc.exists) {
      await _showMessage(context, 'The original post is no longer available.');
      return;
    }

    final post = postDoc.data() ?? <String, dynamic>{};

    await _showDetails(
      context,
      (post['providerName'] ?? 'Service Provider').toString(),
      '${post['caption'] ?? ''}\n\n${notification.body}',
    );
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    NotificationModel notification,
    String userId,
    NotificationService service,
  ) async {
    try {
      await service.markAsRead(notification.id);

      if (!context.mounted) return;

      final notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .get();

      if (!context.mounted) return;

      final data = notificationDoc.data() ?? <String, dynamic>{};

      final type = '${data['type'] ?? notification.type}'.toLowerCase();

      final title = notification.title.toLowerCase();

      final bookingId = notification.bookingId.isNotEmpty
          ? notification.bookingId
          : (data['bookingId'] ?? '').toString();

      final isAccountNotification =
          type == 'account' ||
          title.contains('reactivat') ||
          title.contains('restrict') ||
          title.contains('suspend');

      if (isAccountNotification) {
        await _openAccountNotification(context, notification, userId);
        return;
      }

      final isPostNotification =
          type.contains('post') ||
          type.contains('comment') ||
          type.contains('like') ||
          title.contains('comment') ||
          title.contains('like');

      if (isPostNotification) {
        await _openPostNotification(context, notification, userId, data);
        return;
      }

      final isBookingNotification =
          bookingId.isNotEmpty ||
          type.contains('booking') ||
          title.contains('booking') ||
          title.contains('rescheduled');

      if (isBookingNotification) {
        await _openBooking(context, userId, bookingId);
        return;
      }

      final isRatingNotification =
          type.contains('rating') || title.contains('rating');

      if (isRatingNotification) {
        if (bookingId.isNotEmpty) {
          await _openBooking(context, userId, bookingId);
          return;
        }

        final providerDoc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(userId)
            .get();

        if (!context.mounted) return;

        if (providerDoc.exists) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProviderPortfolioScreen()),
          );
        } else {
          await _showDetails(context, notification.title, notification.body);
        }

        return;
      }

      // Do not leave other notification types unresponsive.
      await _showDetails(context, notification.title, notification.body);
    } catch (e) {
      if (!context.mounted) return;

      await _showMessage(
        context,
        'Unable to open this notification. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Text(
            'Please log in to view notifications.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final userId = user.uid;
    final service = NotificationService();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_background, Color(0xFF061021), Color(0xFF0B192C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<NotificationModel>>(
          stream: service.getUserNotifications(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _blue),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading notifications.',
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      color: _blue,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Updates and alerts will appear here.',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification.isRead;

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C2340), Color(0xFF071325)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? Colors.white.withValues(alpha: 0.08)
                          : _blue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _onNotificationTap(
                        context,
                        notification,
                        userId,
                        service,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF1D4ED8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: _blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    notification.body,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white38,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
