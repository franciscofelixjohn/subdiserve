import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  String _formatTime() {
    if (message.timestamp == null) return '';

    final dateTime = message.timestamp!.toDate();
    return DateFormat('hh:mm a').format(dateTime); // e.g. 08:45 PM
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF0284C7)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: isMe
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
              boxShadow: isMe
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // 🔥 TIME
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _formatTime(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}