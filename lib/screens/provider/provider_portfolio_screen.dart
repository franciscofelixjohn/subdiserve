import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/provider_post_service.dart';

class ProviderPortfolioScreen extends StatefulWidget {
  const ProviderPortfolioScreen({super.key});

  @override
  State<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen> {
  final ProviderPostService _postService = ProviderPostService();
  final bool _isUploading = false;

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      int hour = dateTime.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
    }
  }


  void _showCommentsBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
        child: SizedBox(
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Post Comments & Questions',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                          'No comments from homeowners yet.',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final commentDoc = comments[index];
                        final commentData = commentDoc.data();
                        final commentId = commentDoc.id;
                        final userName = commentData['userName'] ?? 'Homeowner';
                        final homeownerUserId = commentData['userId'] ?? '';
                        final text = commentData['text'] ?? '';
                        final commentTimestamp = commentData['createdAt'] as Timestamp?;
                        final commentTimeAgo = _formatTimeAgo(commentTimestamp);

                        List<dynamic> commentLikes = commentData['likes'] ?? [];
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                        final bool isCommentLiked = currentUserId.isNotEmpty && commentLikes.contains(currentUserId);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(userName, style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                                      if (commentTimeAgo.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(commentTimeAgo, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                                      ],
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if (currentUserId.isEmpty) return;
                                      final ref = FirebaseFirestore.instance
                                          .collection('provider_posts')
                                          .doc(postId)
                                          .collection('comments')
                                          .doc(commentId);
                                      
                                      if (isCommentLiked) {
                                        await ref.update({
                                          'likes': FieldValue.arrayRemove([currentUserId])
                                        });
                                      } else {
                                        await ref.update({
                                          'likes': FieldValue.arrayUnion([currentUserId])
                                        });
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCommentLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isCommentLiked ? Colors.redAccent : Colors.white60,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${commentLikes.length}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 10),
                              
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('provider_posts')
                                    .doc(postId)
                                    .collection('comments')
                                    .doc(commentId)
                                    .collection('replies')
                                    .orderBy('createdAt', descending: false)
                                    .snapshots(),
                                builder: (context, replySnapshot) {
                                  final replies = replySnapshot.data?.docs ?? [];
                                  if (replies.isEmpty) return const SizedBox.shrink();

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 8),
                                    child: Column(
                                      children: replies.map((replyDoc) {
                                        final replyData = replyDoc.data();
                                        final replyName = replyData['userName'] ?? 'Provider';
                                        final replyText = replyData['text'] ?? '';
                                        final replyTimestamp = replyData['createdAt'] as Timestamp?;
                                        final replyTimeAgo = _formatTimeAgo(replyTimestamp);

                                        return Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF38BDF8), size: 14),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(replyName, style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                                                        if (replyTimeAgo.isNotEmpty)
                                                          Text(replyTimeAgo, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(replyText, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    _showReplyDialog(context, postId, commentId, homeownerUserId);
                                  },
                                  icon: const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF38BDF8)),
                                  label: Text('Reply', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                                ),
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
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String postId, String commentId, String homeownerUserId) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.4),
        ),
        title: Text('Reply to Comment', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: replyController,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = replyController.text.trim();
              if (text.isEmpty) return;

              Navigator.pop(context);

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final userDoc = await FirebaseFirestore.instance.collection('providers').doc(user.uid).get();
              final providerName = userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? 'Service Provider';

              await FirebaseFirestore.instance
                  .collection('provider_posts')
                  .doc(postId)
                  .collection('comments')
                  .doc(commentId)
                  .collection('replies')
                  .add({
                'userId': user.uid,
                'userName': providerName,
                'text': text,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (homeownerUserId.isNotEmpty && homeownerUserId != user.uid) {
                await FirebaseFirestore.instance.collection('notifications').add({
                  'userId': homeownerUserId,
                  'recipientId': homeownerUserId,
                  'title': 'New Reply from $providerName',
                  'body': '$providerName replied to your comment: "$text"',
                  'postId': postId,
                  'isRead': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Send', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    'PORTFOLIO MANAGEMENT',
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
                                'My Portfolio & Posts',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Showcase your work and recent projects',
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
                  Expanded(
                    child: user == null
                        ? const Center(child: Text('No current user found.', style: TextStyle(color: Colors.white54)))
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _postService.streamProviderPosts(user.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting || _isUploading) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                              }

                              final posts = snapshot.data?.docs ?? [];

                              if (posts.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.photo_camera_back_rounded, color: Colors.white24, size: 48),
                                      const SizedBox(height: 12),
                                      Text('You have no posts or portfolio yet.', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13.5)),
                                      const SizedBox(height: 4),
                                      Text('Tap the Create Post button from the dashboard to add one.', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: posts.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final postDoc = posts[index];
                                  final post = postDoc.data();
                                  final postId = postDoc.id;
                                  final imageUrl = post['imageUrl'] ?? '';
                                  final caption = post['caption'] ?? '';
                                  final price = post['priceRange'] ?? '';
                                  final List<dynamic> likes = post['likes'] ?? [];
                                  
                                  final timestamp = post['createdAt'] as Timestamp?;
                                  final formattedDate = _formatTimeAgo(timestamp);

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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (imageUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                            child: imageUrl.startsWith('data:image')
                                                ? Image.memory(
                                                    base64Decode(imageUrl.split(',').last),
                                                    height: 190,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    imageUrl,
                                                    height: 190,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  if (price.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(10),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                                            blurRadius: 6,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        price.startsWith('₱') ? price : '₱$price',
                                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                                      ),
                                                    ),
                                                  if (formattedDate.isNotEmpty)
                                                    Text(
                                                      formattedDate,
                                                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                                                    ),
                                                ],
                                              ),
                                              if (price.isNotEmpty || formattedDate.isNotEmpty) const SizedBox(height: 12),
                                              Text(caption, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5)),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                                                      const SizedBox(width: 6),
                                                      Text('${likes.length} likes', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5)),
                                                      const SizedBox(width: 16),
                                                      StreamBuilder<QuerySnapshot>(
                                                        stream: FirebaseFirestore.instance
                                                            .collection('provider_posts')
                                                            .doc(postId)
                                                            .collection('comments')
                                                            .snapshots(),
                                                        builder: (context, commentSnapshot) {
                                                          final commentCount = commentSnapshot.data?.docs.length ?? 0;
                                                          return InkWell(
                                                            onTap: () => _showCommentsBottomSheet(context, postId),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.mode_comment_outlined, color: Colors.white60, size: 18),
                                                                const SizedBox(width: 6),
                                                                Text('$commentCount Comments', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.5)),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () async => await _postService.deletePost(postId),
                                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                    label: Text('Delete', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
            ),
          ),
        ],
      ),
    );
  }
}