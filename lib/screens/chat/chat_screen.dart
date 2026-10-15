import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? bookingId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.bookingId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? chatId;
  bool isSending = false;
  bool isCheckingBooking = true;
  late String resolvedOtherUserName;
  String? resolvedOtherUserPic;
  String? currentUserPic;
  String otherUserBioOrCategory = 'Service Provider';

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    resolvedOtherUserName = widget.otherUserName;
    _verifyBookingAndInitChat();
    _fetchCurrentUserPic();
  }

  Future<void> _fetchCurrentUserPic() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          currentUserPic = userDoc.data()!['profileImageUrl'] ?? userDoc.data()!['photoUrl'];
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _verifyBookingAndInitChat() async {
    try {
      if (widget.otherUserId.isNotEmpty) {
        try {
          final providerDoc = await FirebaseFirestore.instance
              .collection('providers')
              .doc(widget.otherUserId)
              .get();

          if (providerDoc.exists && providerDoc.data() != null) {
            final data = providerDoc.data()!;
            resolvedOtherUserName = data['name'] ?? data['fullName'] ?? resolvedOtherUserName;
            resolvedOtherUserPic = data['profileImageUrl'] ?? data['photoUrl'];
            
            final service = data['service'] ?? data['serviceCategory'] ?? 'Carpenter / Service Provider';
            final rating = data['rating'] != null ? ' • ⭐ ${data['rating']}' : '';
            otherUserBioOrCategory = '$service$rating';
          } else {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.otherUserId)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              final fName = data['firstName'] ?? '';
              final lName = data['lastName'] ?? '';
              if (fName.isNotEmpty || lName.isNotEmpty) {
                resolvedOtherUserName = '$fName $lName'.trim();
              } else if (data['name'] != null) {
                resolvedOtherUserName = data['name'];
              }
              resolvedOtherUserPic ??= data['profileImageUrl'] ?? data['photoUrl'];
              otherUserBioOrCategory = 'Homeowner';
            }
          }
        } catch (e) {
          // Ignore error
        }
      }

      final id = await _chatService.createOrGetChat(
        currentUserId: currentUserId,
        otherUserId: widget.otherUserId,
        bookingId: widget.bookingId,
        currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        otherUserName: resolvedOtherUserName,
      );

      if (!mounted) return;

      setState(() {
        chatId = id;
        isCheckingBooking = false;
      });

      _markMessagesAsSeen(id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat')),
      );
    }
  }

  Future<void> _markMessagesAsSeen(String activeChatId) async {
    try {
      final messagesQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(activeChatId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.otherUserId)
          .get();

      for (var doc in messagesQuery.docs) {
        final data = doc.data();
        if (data['isSeen'] != true) {
          await doc.reference.update({
            'isSeen': true,
            'seenAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  void _scrollToLatestMessage() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (chatId == null || text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await _chatService.sendMessage(
        chatId: chatId!,
        senderId: currentUserId,
        text: text,
      );

      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId!)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.set({
          'isSeen': false,
        }, SetOptions(merge: true));
      }

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLatestMessage();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // Function to delete or unsend a message
  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message unsent successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  // Dialog for confirming message deletion/unsend
  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Unsend Message',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Do you want to delete this message?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  Widget _buildAvatar(String name, String? imageUrl, {double size = 32}) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? (imageUrl.startsWith('data:image')
                ? Image.memory(
                    base64Decode(imageUrl.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallback(name, size),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallback(name, size),
                  ))
            : _buildFallback(name, size),
      ),
    );
  }

  Widget _buildFallback(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingBooking || chatId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030712),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(resolvedOtherUserName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('providers')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, providerSnapshot) {
            bool isOnline = true;

            if (providerSnapshot.hasData && providerSnapshot.data != null && providerSnapshot.data!.exists) {
              final pData = providerSnapshot.data!.data() as Map<String, dynamic>?;
              final avail = pData?['availabilityStatus'] ?? 'available';
              if (avail == 'busy') isOnline = false;
            }

            return Row(
              children: [
                _buildAvatar(resolvedOtherUserName, resolvedOtherUserPic, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedOtherUserName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'Active now' : 'Offline',
                        style: GoogleFonts.poppins(
                          color: isOnline ? Colors.greenAccent : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId!)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading messages', style: TextStyle(color: Colors.white54)),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToLatestMessage();
                    });

                    final itemCount = docs.length + 1;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAvatar(resolvedOtherUserName, resolvedOtherUserPic, size: 84),
                                const SizedBox(height: 14),
                                Text(
                                  resolvedOtherUserName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  otherUserBioOrCategory,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                              ],
                            ),
                          );
                        }

                        final doc = docs[index];
                        final docData = doc.data() as Map<String, dynamic>;
                        final messageId = doc.id;
                        final senderId = docData['senderId'] ?? '';
                        final text = docData['text'] ?? '';
                        final timestamp = docData['timestamp'] as Timestamp?;
                        final isSeen = docData['isSeen'] ?? false;
                        final seenAt = docData['seenAt'] as Timestamp?;

                        final isMe = senderId == currentUserId;
                        final timeString = _formatTime(timestamp);
                        final seenTimeString = _formatTime(seenAt);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildAvatar(resolvedOtherUserName, resolvedOtherUserPic, size: 30),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      // Long press to show delete/unsend option if the message belongs to current user
                                      onLongPress: isMe ? () => _showDeleteDialog(messageId) : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: isMe
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isMe ? null : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(20),
                                            topRight: const Radius.circular(20),
                                            bottomLeft: Radius.circular(isMe ? 20 : 6),
                                            bottomRight: Radius.circular(isMe ? 6 : 20),
                                          ),
                                          border: Border.all(
                                            color: isMe ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Text(
                                          text,
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isMe) ...[
                                          Text(
                                            isSeen ? 'Seen • $seenTimeString' : 'Sent • $timeString',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.4),
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (isSeen) ...[
                                            const SizedBox(width: 4),
                                            _buildAvatar(resolvedOtherUserName, resolvedOtherUserPic, size: 14),
                                          ],
                                        ] else ...[
                                          Text(
                                            timeString,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.4),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) const SizedBox(width: 6),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712).withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: isSending ? null : _sendMessage,
                          icon: isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}