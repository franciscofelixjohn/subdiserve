import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../homeowner/create_booking_screen.dart';
import '../chat/chat_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryTitle;

  const ProviderListScreen({
    super.key,
    required this.categoryTitle,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getDisplayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['fullName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return 'Unnamed Provider';
  }

  String getServiceCategory(Map<String, dynamic> data) {
    final category = (data['service'] ??
            data['serviceCategory'] ??
            data['category'] ??
            '')
        .toString()
        .trim();
    if (category.isNotEmpty) return category;
    return 'General Service';
  }

  String getEmail(Map<String, dynamic> data) {
    final email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email;
    return 'No email available';
  }

  String getBio(Map<String, dynamic> data) {
    final bio = (data['bio'] ?? data['experience'] ?? 'Professional home service provider.').toString().trim();
    return bio;
  }

  String? getProviderImageUrl(Map<String, dynamic> data) {
    final url = data['profileImageUrl'] ??
        data['selfieUrl'] ??
        data['validIdUrl'] ??
        data['photoUrl'] ??
        data['profilePic'] ??
        data['avatarUrl'];
    if (url != null && url.toString().trim().isNotEmpty) {
      return url.toString().trim();
    }
    return null;
  }

  bool matchesCategory(String providerCategory, String selectedCategory) {
    final providerValue = providerCategory.toLowerCase().trim();
    final selectedValue = selectedCategory.toLowerCase().trim();

    if (providerValue == selectedValue) return true;
    if (selectedValue == 'plumbing' && providerValue.contains('plumb')) return true;
    if (selectedValue == 'electrical work' && (providerValue.contains('electrical') || providerValue.contains('electrician'))) return true;
    if (selectedValue == 'house cleaning' && providerValue.contains('clean')) return true;
    if (selectedValue == 'aircon maintenance' && providerValue.contains('aircon')) return true;
    if (selectedValue == 'appliance repair' && providerValue.contains('appliance')) return true;

    return false;
  }

  Widget _buildImageWidget(String? imageUrl, String fallbackName) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.startsWith('demo')) {
      return _buildAvatarFallback(fallbackName);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackName),
        );
      } catch (_) {
        return _buildAvatarFallback(fallbackName);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackName),
    );
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

  void _showProviderMarketplaceModal(
    BuildContext context, {
    required String providerId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('providers').doc(providerId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'Provider details not found.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
              );
            }

            final data = snapshot.data!.data() ?? {};
            final providerName = getDisplayName(data);
            final providerCategory = getServiceCategory(data);
            final email = getEmail(data);
            final bio = getBio(data);
            final double avgRating = ((data['averageRating'] ?? 0) as num).toDouble();
            final int ratingCount = (data['ratingCount'] ?? 0) as int;
            final String? imageUrl = getProviderImageUrl(data);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          child: _buildImageWidget(imageUrl, providerName),
                        ),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                providerCategory,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'About / Bio',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Provider Details & Contact',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 10),
                      Text(email, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        ratingCount > 0 ? '${avgRating.toStringAsFixed(1)} Rating ($ratingCount reviews)' : 'No ratings yet',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'Portfolio & Work Posts',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('provider_posts')
                        .where('providerId', isEqualTo: providerId)
                        .snapshots(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
                        );
                      }

                      final posts = postSnapshot.data?.docs ?? [];

                      if (posts.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            'This provider has not posted any portfolio work yet.',
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12.5),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final postDoc = posts[index];
                          final postData = postDoc.data();
                          final postId = postDoc.id;
                          final caption = postData['caption'] ?? '';
                          final priceRange = postData['priceRange'] ?? '';
                          
                          List<dynamic> rawImages = postData['imageList'] ?? [];
                          if (rawImages.isEmpty && postData['imageUrl'] != null) {
                            rawImages = [postData['imageUrl']];
                          }

                          List<dynamic> likes = postData['likes'] ?? [];
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          final bool isLiked = currentUserId.isNotEmpty && likes.contains(currentUserId);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (rawImages.isNotEmpty)
                                  SizedBox(
                                    height: 190,
                                    child: PageView.builder(
                                      itemCount: rawImages.length,
                                      itemBuilder: (context, imgIndex) {
                                        final imgStr = rawImages[imgIndex].toString();
                                        return ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: imgStr.startsWith('data:image')
                                              ? Image.memory(
                                                  Uri.parse(imgStr).data!.contentAsBytes(),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  imgStr,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => const SizedBox(),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (priceRange.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            priceRange,
                                            style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      if (priceRange.isNotEmpty) const SizedBox(height: 8),
                                      Text(
                                        caption,
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              if (currentUserId.isEmpty) return;
                                              final ref = FirebaseFirestore.instance.collection('provider_posts').doc(postId);
                                              if (isLiked) {
                                                await ref.update({
                                                  'likes': FieldValue.arrayRemove([currentUserId])
                                                });
                                              } else {
                                                await ref.update({
                                                  'likes': FieldValue.arrayUnion([currentUserId])
                                                });

                                                final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
                                                final homeownerName = userDoc.data()?['name'] ?? 'A homeowner';

                                                await FirebaseFirestore.instance.collection('notifications').add({
                                                  'userId': providerId,
                                                  'recipientId': providerId,
                                                  'title': 'New Like on Your Post',
                                                  'body': '$homeownerName liked your portfolio post.',
                                                  'postId': postId,
                                                  'createdAt': FieldValue.serverTimestamp(),
                                                  'isRead': false,
                                                });
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                  color: isLiked ? Colors.redAccent : Colors.white60,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${likes.length}',
                                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('provider_posts')
                                                .doc(postId)
                                                .collection('comments')
                                                .snapshots(),
                                            builder: (context, commentSnapshot) {
                                              final commentCount = commentSnapshot.data?.docs.length ?? 0;
                                              return InkWell(
                                                onTap: () => _showCommentsBottomSheet(context, postId, providerId),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.mode_comment_outlined, color: Colors.white60, size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '$commentCount Comments',
                                                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: providerId,
                                  otherUserName: providerName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                          label: Text('Chat Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateBookingScreen(
                                  providerId: providerId,
                                  providerName: providerName,
                                  providerCategory: providerCategory,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 16),
                          label: Text('Book Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET PARA SA COMMENTER PROFILE PICTURE (Hinahanap sa users o providers collection) ---
  Widget _buildCommentUserAvatar(String userId, String userName) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnap) {
        String? imgUrl;
        if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
          final data = userSnap.data!.data() as Map<String, dynamic>?;
          imgUrl = data?['profileImageUrl'] ?? data?['selfieUrl'] ?? data?['photoUrl'] ?? data?['validIdUrl'];
        }

        if (imgUrl != null && imgUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 34,
              height: 34,
              child: _buildImageWidget(imgUrl, userName),
            ),
          );
        }

        // Kung wala sa users, subukan naman sa providers collection
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('providers').doc(userId).get(),
          builder: (context, providerSnap) {
            String? pImgUrl;
            if (providerSnap.hasData && providerSnap.data != null && providerSnap.data!.exists) {
              final pData = providerSnap.data!.data() as Map<String, dynamic>?;
              pImgUrl = pData?['profileImageUrl'] ?? pData?['selfieUrl'] ?? pData?['photoUrl'] ?? pData?['validIdUrl'];
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 34,
                height: 34,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                child: pImgUrl != null && pImgUrl.isNotEmpty
                    ? _buildImageWidget(pImgUrl, userName)
                    : _buildAvatarFallback(userName),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsBottomSheet(BuildContext context, String postId, String providerId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SizedBox(
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments & Questions',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
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
                          'No comments yet. Be the first to ask!',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final commentDoc = comments[index];
                        final commentData = commentDoc.data();
                        final commentId = commentDoc.id;
                        final commenterUserId = commentData['userId'] ?? '';
                        final userName = commentData['userName'] ?? 'User';
                        final text = commentData['text'] ?? '';
                        List<dynamic> commentLikes = commentData['likes'] ?? [];
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                        final bool isCommentLiked = currentUserId.isNotEmpty && commentLikes.contains(currentUserId);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
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
                                      _buildCommentUserAvatar(commenterUserId, userName),
                                      const SizedBox(width: 10),
                                      Text(
                                        userName,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF38BDF8),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${commentLikes.length}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 44),
                                child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                              ),
                              const SizedBox(height: 8),

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
                                    padding: const EdgeInsets.only(left: 44, top: 6),
                                    child: Column(
                                      children: replies.map((replyDoc) {
                                        final replyData = replyDoc.data();
                                        final replyUserId = replyData['userId'] ?? '';
                                        final replyName = replyData['userName'] ?? 'Provider';
                                        final replyText = replyData['text'] ?? '';
                                        return Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildCommentUserAvatar(replyUserId, replyName),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(replyName, style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
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
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Write a comment or question...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                      final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Homeowner';

                      await FirebaseFirestore.instance
                          .collection('provider_posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                        'userId': user.uid,
                        'userName': userName,
                        'text': text,
                        'createdAt': FieldValue.serverTimestamp(),
                        'likes': [],
                      });

                      await FirebaseFirestore.instance.collection('notifications').add({
                        'userId': providerId,
                        'recipientId': providerId,
                        'title': 'New Comment on Your Post',
                        'body': '$userName commented on your post: "$text"',
                        'postId': postId,
                        'createdAt': FieldValue.serverTimestamp(),
                        'isRead': false,
                      });

                      commentController.clear();
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providersStream = FirebaseFirestore.instance.collection('providers').snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search marketplace provider...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.35), fontSize: 13.5),
                      prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF38BDF8).withValues(alpha: 0.8)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: providersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;

                      final filteredDocs = allDocs.where((doc) {
                        if (currentUid != null && doc.id == currentUid) return false;
                        final data = doc.data();
                        final serviceCategory = getServiceCategory(data);
                        final name = getDisplayName(data).toLowerCase();

                        return matchesCategory(serviceCategory, widget.categoryTitle) && name.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, color: Colors.white38, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No marketplace listings found for "${widget.categoryTitle}".',
                                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data();

                          final providerId = doc.id;
                          final providerName = getDisplayName(data);
                          final providerCategory = getServiceCategory(data);
                          final bioSnippet = getBio(data);
                          final double avgRating = ((data['averageRating'] ?? 0) as num).toDouble();
                          final int ratingCount = (data['ratingCount'] ?? 0) as int;
                          
                          final String? profileImgUrl = getProviderImageUrl(data);

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
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.4),
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
                                onTap: () => _showProviderMarketplaceModal(
                                  context,
                                  providerId: providerId,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: _buildImageWidget(profileImgUrl, providerName),
                                            ),
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
                                                  providerCategory,
                                                  style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ChatScreen(
                                                    otherUserId: providerId,
                                                    otherUserName: providerName,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF38BDF8), size: 18),
                                            style: IconButton.styleFrom(
                                              backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.all(10),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                                                const SizedBox(width: 4),
                                                Text(
                                                  ratingCount > 0 ? '${avgRating.toStringAsFixed(1)} ($ratingCount reviews)' : 'No ratings yet',
                                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              bioSnippet,
                                              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}