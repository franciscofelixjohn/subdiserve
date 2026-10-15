import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles the "Work Progress" timeline for a booking: providers post
/// updates (a photo + a day label like "Day 1" + a short note) as they
/// work on the job, and homeowners/admins can view that same timeline.
///
/// Data is stored as a subcollection so it scales cleanly per booking:
///   bookings/{bookingId}/progress_updates/{autoId}
///
/// Photos are stored as base64 strings directly on the document (resized
/// and compressed on the client via image_picker) so this works without
/// needing to set up Firebase Storage separately.
class ProgressService {
  final CollectionReference<Map<String, dynamic>> _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');

  CollectionReference<Map<String, dynamic>> _progressRef(String bookingId) {
    return _bookingsRef.doc(bookingId).collection('progress_updates');
  }

  /// Adds a new progress update for a booking.
  Future<void> addProgressUpdate({
    required String bookingId,
    required String providerId,
    required String dayLabel,
    required String note,
    String? photoBase64,
  }) async {
    await _progressRef(bookingId).add({
      'providerId': providerId,
      'dayLabel': dayLabel.trim(),
      'note': note.trim(),
      'photoBase64': photoBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Live stream of progress updates for a booking, oldest first (Day 1,
  /// Day 2, ... in order).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProgressUpdates(
    String bookingId,
  ) {
    return _progressRef(bookingId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteProgressUpdate({
    required String bookingId,
    required String updateId,
  }) async {
    await _progressRef(bookingId).doc(updateId).delete();
  }
}