import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String bookingId;
  final Timestamp? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.bookingId,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      isRead: data['isRead'] ?? false,
      bookingId: data['bookingId'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}