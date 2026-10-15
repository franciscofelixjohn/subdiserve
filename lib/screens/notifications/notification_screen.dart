import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../provider/provider_portfolio_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.15),
                    const Color(0xFF0284C7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: StreamBuilder<List<NotificationModel>>(
                stream: notificationService.getUserNotifications(currentUserId),
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
                        'Error loading notifications',
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
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
                              Icons.notifications_off_outlined,
                              color: Color(0xFF38BDF8),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Updates and alerts will appear here.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final bool isRead = notification.isRead;

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
                                : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            width: isRead ? 1 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await notificationService.markAsRead(notification.id);

                              final doc = await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notification.id)
                                  .get();
                              
                              final data = doc.data();
                              String? postId;
                              if (data != null && data.containsKey('postId')) {
                                postId = data['postId'];
                              }

                              if (!context.mounted) return;

                              if (postId != null && postId.isNotEmpty) {
                                final providerCheck = await FirebaseFirestore.instance
                                    .collection('providers')
                                    .doc(currentUserId)
                                    .get();

                                if (!context.mounted) return;

                                if (providerCheck.exists) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProviderPortfolioScreen(),
                                    ),
                                  );
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: const Color(0xFF061021),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                                      child: SizedBox(
                                        height: 450,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Post Comments & Questions',
                                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 10),
                                            Expanded(
                                              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                                stream: FirebaseFirestore.instance
                                                    .collection('provider_posts')
                                                    .doc(postId)
                                                    .collection('comments')
                                                    .orderBy('createdAt', descending: true)
                                                    .snapshots(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                                                  }

                                                  final comments = snapshot.data?.docs ?? [];

                                                  if (comments.isEmpty) {
                                                    return Center(
                                                      child: Text(
                                                        'No comments yet.',
                                                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                                                      ),
                                                    );
                                                  }

                                                  return ListView.separated(
                                                    itemCount: comments.length,
                                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                                    itemBuilder: (context, index) {
                                                      final commentData = comments[index].data();
                                                      final userName = commentData['userName'] ?? 'User';
                                                      final text = commentData['text'] ?? '';

                                                      return Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withValues(alpha: 0.04),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(userName, style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                                                            const SizedBox(height: 4),
                                                            Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
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
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Notification: ${notification.title}', style: GoogleFonts.poppins(color: Colors.white)),
                                    backgroundColor: const Color(0xFF0284C7),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.notifications_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                  color: Color(0xFF38BDF8),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification.body,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
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
          ),
        ],
      ),
    );
  }
}