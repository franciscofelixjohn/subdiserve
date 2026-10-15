import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_list_model.dart';

class ChatListTile extends StatefulWidget {
  final ChatListModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile> {
  String otherUserName = 'Loading...';
  String serviceLabel = '';

  @override
  void initState() {
    super.initState();
    _resolveUserInfo();
  }

  Future<void> _resolveUserInfo() async {
    final otherUserId = widget.chat.participants.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isNotEmpty) {
      String resolvedName = '';

      try {
        // 1. Unahing hanapin muna sa 'providers' collection (kung ang kausap ay service provider)
        final providerDoc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(otherUserId)
            .get();

        if (providerDoc.exists && providerDoc.data() != null) {
          final data = providerDoc.data()!;
          resolvedName = data['name'] ?? data['fullName'] ?? '';
        }

        // 2. Kung walang nahanap sa providers, hanapin naman sa 'users' collection (kung ang kausap ay client)
        if (resolvedName.isEmpty || resolvedName == 'User') {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            resolvedName = data['fullName'] ?? data['name'] ?? '';
          }
        }
      } catch (e) {
        // Ignore error
      }

      // 3. Fallback sa participantNames kung wala pa rin
      if (resolvedName.isEmpty || resolvedName == 'User') {
        final nameFromChat = widget.chat.participantNames[otherUserId];
        if (nameFromChat != null &&
            nameFromChat.toString().isNotEmpty &&
            nameFromChat.toString() != 'User') {
          resolvedName = nameFromChat.toString();
        }
      }

      otherUserName = (resolvedName.isNotEmpty && resolvedName != 'User')
          ? resolvedName
          : 'User';
    } else {
      otherUserName = 'User';
    }

    // Kunin ang service label mula sa bookings
    if (widget.chat.bookingId.isNotEmpty) {
      try {
        final bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.chat.bookingId)
            .get();

        if (bookingDoc.exists && bookingDoc.data() != null) {
          final data = bookingDoc.data()!;
          serviceLabel = data['serviceName'] ?? data['service'] ?? '';
        }
      } catch (e) {
        // Ignore error
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 22,
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
                              otherUserName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (serviceLabel.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                serviceLabel,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.chat.lastMessage.isEmpty
                            ? 'No messages yet'
                            : widget.chat.lastMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}