import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_list_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<String> createOrGetChat({
    required String currentUserId,
    required String otherUserId,
    String? bookingId,
    String? currentUserName,
    String? otherUserName,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': ([currentUserId, otherUserId]..sort()),
        'participantNames': {
          currentUserId: currentUserName ?? 'User',
          otherUserId: otherUserName ?? 'User',
        },
        'bookingId': bookingId ?? '',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<ChatListModel>> getUserChats(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatListModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}