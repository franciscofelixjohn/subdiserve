import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/chat_list_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/provider_bottom_nav_bar.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isProvider = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Check if the current user is a service provider or homeowner
  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final role = doc.data()!['role'] ?? 'homeowner';
          if (mounted) {
            setState(() {
              _isProvider = role.toString().toLowerCase() == 'service_provider' || 
                          role.toString().toLowerCase() == 'provider';
              _isLoadingRole = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: _isLoadingRole
          ? null
          : (_isProvider
              ? const ProviderBottomNavBar(currentIndex: 3)
              : const CustomBottomNavBar(currentIndex: 2)),
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
                              'INBOX & CHATS',
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
                          'Messages',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isProvider
                              ? 'Communicate live with your clients'
                              : 'Communicate live with your service providers',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- LIVE FIRESTORE CHATS LIST ---
                  Expanded(
                    child: StreamBuilder<List<ChatListModel>>(
                      stream: chatService.getUserChats(currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting || _isLoadingRole) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF38BDF8),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading chats',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                              ),
                            ),
                          );
                        }

                        final chats = snapshot.data ?? [];

                        if (chats.isEmpty) {
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
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No conversations yet',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isProvider
                                      ? 'Your chats with clients will appear here'
                                      : 'Your chats with providers will appear here',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: chats.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final chat = chats[index];

                            final otherUserId = chat.participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            );

                            if (otherUserId.isEmpty) {
                              return const SizedBox();
                            }

                            final fallbackName =
                                chat.participantNames[otherUserId] ?? 'User';
                            
                            final String lastMessage = chat.lastMessage.isNotEmpty 
                                ? chat.lastMessage 
                                : 'No messages yet';

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(otherUserId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                String otherUserName = fallbackName;
                                String? otherUserPic;

                                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                  if (userData != null) {
                                    final fName = userData['firstName'] ?? '';
                                    final lName = userData['lastName'] ?? '';
                                    if (fName.isNotEmpty || lName.isNotEmpty) {
                                      otherUserName = '$fName $lName'.trim();
                                    } else if (userData['name'] != null) {
                                      otherUserName = userData['name'];
                                    }
                                    otherUserPic = userData['profileImageUrl'] ?? userData['photoUrl'];
                                  }
                                } else {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('providers')
                                        .doc(otherUserId)
                                        .get(),
                                    builder: (context, providerSnapshot) {
                                      String providerName = fallbackName;
                                      String? providerPic;

                                      if (providerSnapshot.hasData && providerSnapshot.data != null && providerSnapshot.data!.exists) {
                                        final providerData = providerSnapshot.data!.data() as Map<String, dynamic>?;
                                        if (providerData != null) {
                                          providerName = providerData['name'] ?? providerData['fullName'] ?? fallbackName;
                                          providerPic = providerData['profileImageUrl'] ?? providerData['photoUrl'];
                                        }
                                      }

                                      return _buildChatTile(
                                        context,
                                        otherUserId: otherUserId,
                                        otherUserName: providerName,
                                        otherUserPic: providerPic,
                                        lastMessage: lastMessage,
                                        chat: chat,
                                      );
                                    },
                                  );
                                }

                                return _buildChatTile(
                                  context,
                                  otherUserId: otherUserId,
                                  otherUserName: otherUserName,
                                  otherUserPic: otherUserPic,
                                  lastMessage: lastMessage,
                                  chat: chat,
                                );
                              },
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

  // Elite Chat Tile Widget
  Widget _buildChatTile(
    BuildContext context, {
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPic,
    required String lastMessage,
    required ChatListModel chat,
  }) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  bookingId: chat.bookingId.isEmpty
                      ? null
                      : chat.bookingId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
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
                    child: _buildImageWidget(otherUserPic, otherUserName),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF38BDF8),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}