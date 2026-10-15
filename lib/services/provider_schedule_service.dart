import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class ProviderScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookingModel>> getProviderBookings(String providerId) {
    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }
}