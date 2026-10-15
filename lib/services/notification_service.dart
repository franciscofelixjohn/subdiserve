import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String bookingId = '',
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get notifications of current user (sorted client-side to avoid
  // needing a Firestore composite index for where + orderBy together)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();

      list.sort((a, b) {
        final aTs = a.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTs = b.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTs.compareTo(aTs); // newest first
      });

      return list;
    });
  }

  // Live count of unread notifications, for a badge on the bell icon.
  // Filters client-side (instead of a second .where()) to avoid needing
  // a Firestore composite index.
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.where((d) => d.data()['isRead'] != true).length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark every notification for this user as read (e.g. when they open
  // the notifications screen).
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final unread =
        snapshot.docs.where((d) => d.data()['isRead'] != true).toList();
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}