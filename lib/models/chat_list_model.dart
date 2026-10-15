class ChatListModel {
  final String id;
  final List<dynamic> participants;
  final Map<String, dynamic> participantNames;
  final String bookingId;
  final String lastMessage;

  ChatListModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.bookingId,
    required this.lastMessage,
  });

  factory ChatListModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatListModel(
      id: id,
      participants: map['participants'] ?? [],
      participantNames: Map<String, dynamic>.from(
        map['participantNames'] ?? {},
      ),
      bookingId: map['bookingId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
    );
  }
}