import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 GET PROVIDER BOOKINGS
  Stream<List<BookingModel>> getProviderBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  // 🔥 GET ACCEPTED BOOKINGS (for schedule page)
  Stream<List<BookingModel>> getAcceptedBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  // 🔥 UPDATE STATUS
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }
}