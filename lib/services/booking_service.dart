import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('bookings');

  // ✅ NEW: CREATE BOOKING
  Future<String> createBooking({
    required String homeownerId,
    required String homeownerName,
    required String homeownerEmail,
    required String providerId,
    required String providerName,
    required String providerCategory,
    required String service,
    required String address,
    required String notes,
    required DateTime bookingDateTime,
    required String bookingDate,
    required String bookingTime,
  }) async {
    final bookingRef = _bookingsRef.doc();

    await bookingRef.set({
      'bookingId': bookingRef.id,
      'homeownerId': homeownerId,
      'homeownerName': homeownerName,
      'homeownerEmail': homeownerEmail,
      'providerId': providerId,
      'providerName': providerName,
      'providerCategory': providerCategory,
      'service': service,
      'address': address,
      'notes': notes,
      'selectedDate': Timestamp.fromDate(bookingDateTime),
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.createNotification(
      userId: providerId,
      title: 'New Booking Request',
      body: '$homeownerName requested "$service" on $bookingDate at $bookingTime.',
      type: 'booking',
      bookingId: bookingRef.id,
    );

    return bookingRef.id;
  }

  Stream<List<BookingModel>> getPendingBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getAcceptedBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getCompletedBookings(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _bookingsRef
        .where('homeownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();

      list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      return list;
    });
  }

  Future<int> getAcceptedJobsCount(String providerId) async {
    final snapshot = await _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return snapshot.docs.length;
  }

  Future<double> getWeeklyEarnings(String providerId) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final snapshot = await _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      DateTime? bookingDate;
      final rawSelectedDate = data['selectedDate'];

      if (rawSelectedDate is Timestamp) {
        bookingDate = rawSelectedDate.toDate();
      } else if (rawSelectedDate is DateTime) {
        bookingDate = rawSelectedDate;
      }

      if (bookingDate == null) continue;

      final bookingDay = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );

      if (bookingDay.isBefore(startOfWeek)) continue;

      final rawPrice =
          data['price'] ?? data['servicePrice'] ?? data['amount'] ?? 0;

      if (rawPrice is int) {
        total += rawPrice.toDouble();
      } else if (rawPrice is double) {
        total += rawPrice;
      } else if (rawPrice is String) {
        total += double.tryParse(rawPrice) ?? 0;
      }
    }

    return total;
  }

  Stream<Map<String, dynamic>> getProviderDashboardStats(String providerId) {
    return _bookingsRef
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      int acceptedJobs = 0;
      double weeklyEarnings = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();

        if (status == 'accepted') {
          acceptedJobs++;
        }

        if (status == 'completed') {
          DateTime? bookingDate;
          final rawSelectedDate = data['selectedDate'];

          if (rawSelectedDate is Timestamp) {
            bookingDate = rawSelectedDate.toDate();
          } else if (rawSelectedDate is DateTime) {
            bookingDate = rawSelectedDate;
          }

          if (bookingDate != null) {
            final bookingDay = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
            );

            if (!bookingDay.isBefore(startOfWeek)) {
              final rawPrice =
                  data['price'] ?? data['servicePrice'] ?? data['amount'] ?? 0;

              if (rawPrice is int) {
                weeklyEarnings += rawPrice.toDouble();
              } else if (rawPrice is double) {
                weeklyEarnings += rawPrice;
              } else if (rawPrice is String) {
                weeklyEarnings += double.tryParse(rawPrice) ?? 0;
              }
            }
          }
        }
      }

      return {
        'acceptedJobs': acceptedJobs,
        'weeklyEarnings': weeklyEarnings,
      };
    });
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? reason,
    String? cancelledBy,
  }) async {
    final normalizedNewStatus = newStatus.trim().toLowerCase();

    String homeownerId = '';
    String providerId = '';
    String homeownerName = '';
    String providerName = '';
    String service = '';

    await _firestore.runTransaction((transaction) async {
      final docRef = _bookingsRef.doc(bookingId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Booking not found.');
      }

      final data = snapshot.data();
      if (data == null) {
        throw Exception('Booking data is empty.');
      }

      homeownerId = (data['homeownerId'] ?? '').toString();
      providerId = (data['providerId'] ?? '').toString();
      homeownerName = (data['homeownerName'] ?? 'Homeowner').toString();
      providerName = (data['providerName'] ?? 'Provider').toString();
      service = (data['service'] ?? 'Service').toString();

      final currentStatus = (data['status'] ?? '').toString().toLowerCase();

      if (!_isValidStatus(normalizedNewStatus)) {
        throw Exception('Invalid target booking status: $normalizedNewStatus');
      }

      if (!_canTransition(currentStatus, normalizedNewStatus)) {
        throw Exception(
          'Invalid booking status transition: $currentStatus -> $normalizedNewStatus',
        );
      }

      final updateData = <String, dynamic>{
        'status': normalizedNewStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (normalizedNewStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedNewStatus == 'rejected') {
        updateData['declineReason'] = reason ?? '';
        updateData['declinedAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedNewStatus == 'cancelled') {
        updateData['cancelReason'] = reason ?? '';
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
        updateData['cancelledBy'] = cancelledBy ?? 'homeowner';
      }

      transaction.update(docRef, updateData);
    });

    // Notify whichever party needs to know about this change.
    switch (normalizedNewStatus) {
      case 'accepted':
        await _notificationService.createNotification(
          userId: homeownerId,
          title: 'Booking Accepted',
          body: '$providerName accepted your "$service" booking.',
          type: 'booking',
          bookingId: bookingId,
        );
        break;
      case 'rejected':
        await _notificationService.createNotification(
          userId: homeownerId,
          title: 'Booking Declined',
          body: '$providerName declined your "$service" booking'
              '${(reason ?? '').isNotEmpty ? ': $reason' : '.'}',
          type: 'booking',
          bookingId: bookingId,
        );
        break;
      case 'cancelled':
        await _notificationService.createNotification(
          userId: providerId,
          title: 'Booking Cancelled',
          body: '$homeownerName cancelled the "$service" booking'
              '${(reason ?? '').isNotEmpty ? ': $reason' : '.'}',
          type: 'booking',
          bookingId: bookingId,
        );
        break;
      case 'completed':
        await _notificationService.createNotification(
          userId: homeownerId,
          title: 'Job Completed',
          body: '$providerName marked "$service" as completed. Don\'t forget to rate your experience!',
          type: 'booking',
          bookingId: bookingId,
        );
        break;
    }
  }

  /// Reschedules an existing booking to a new date/time. Works for
  /// 'pending' or 'accepted' bookings only, and can be initiated by
  /// either the homeowner or the provider. Keeps a running history of
  /// past reschedules on the booking doc for transparency, and notifies
  /// whichever party didn't make the change.
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDateTime,
    required String newBookingDate,
    required String newBookingTime,
    required String rescheduledBy, // 'homeowner' or 'provider'
    String? reason,
  }) async {
    final docRef = _bookingsRef.doc(bookingId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Booking not found.');
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception('Booking data is empty.');
    }

    final currentStatus = (data['status'] ?? '').toString().toLowerCase();
    if (currentStatus != 'pending' && currentStatus != 'accepted') {
      throw Exception('Only pending or accepted bookings can be rescheduled.');
    }

    final oldBookingDate = (data['bookingDate'] ?? '').toString();
    final oldBookingTime = (data['bookingTime'] ?? '').toString();
    final homeownerId = (data['homeownerId'] ?? '').toString();
    final providerId = (data['providerId'] ?? '').toString();
    final homeownerName = (data['homeownerName'] ?? 'Homeowner').toString();
    final providerName = (data['providerName'] ?? 'Provider').toString();
    final service = (data['service'] ?? 'Service').toString();

    final historyEntry = {
      'oldDate': oldBookingDate,
      'oldTime': oldBookingTime,
      'newDate': newBookingDate,
      'newTime': newBookingTime,
      'rescheduledBy': rescheduledBy,
      'reason': (reason ?? '').trim(),
      'rescheduledAt': Timestamp.fromDate(DateTime.now()),
    };

    await docRef.update({
      'selectedDate': Timestamp.fromDate(newDateTime),
      'bookingDate': newBookingDate,
      'bookingTime': newBookingTime,
      'updatedAt': FieldValue.serverTimestamp(),
      'rescheduleHistory': FieldValue.arrayUnion([historyEntry]),
    });

    // Notify whichever party did NOT initiate the reschedule.
    final notifyUserId =
        rescheduledBy == 'homeowner' ? providerId : homeownerId;
    final initiatorName =
        rescheduledBy == 'homeowner' ? homeownerName : providerName;

    await _notificationService.createNotification(
      userId: notifyUserId,
      title: 'Booking Rescheduled',
      body: '$initiatorName moved "$service" to $newBookingDate at $newBookingTime'
          '${(reason ?? '').isNotEmpty ? ' ($reason)' : '.'}',
      type: 'booking',
      bookingId: bookingId,
    );
  }


  Future<void> submitBookingRating({
    required String bookingId,
    required String providerId,
    required String providerCategory,
    required double rating,
    required String comment,
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingRef);

      if (!snapshot.exists) {
        throw Exception('Booking not found.');
      }

      transaction.update(bookingRef, {
        'rating': rating,
        'comment': comment,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    });

    final providerCategoryRatingRef = _firestore
        .collection('providers')
        .doc(providerId)
        .collection('category_ratings')
        .doc(providerCategory.toLowerCase());

    final catDoc = await providerCategoryRatingRef.get();
    
    if (catDoc.exists) {
      final data = catDoc.data()!;
      final double currentTotalRating = (data['totalRating'] ?? 0.0).toDouble();
      final int currentCount = (data['ratingCount'] ?? 0).toInt();

      final newCount = currentCount + 1;
      final newAverage = (currentTotalRating + rating) / newCount;

      await providerCategoryRatingRef.set({
        'category': providerCategory,
        'totalRating': currentTotalRating + rating,
        'ratingCount': newCount,
        'averageRating': newAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await providerCategoryRatingRef.set({
        'category': providerCategory,
        'totalRating': rating,
        'ratingCount': 1,
        'averageRating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  bool _isValidStatus(String status) {
    return status == 'pending' ||
        status == 'accepted' ||
        status == 'rejected' ||
        status == 'completed' ||
        status == 'cancelled';
  }

  bool _canTransition(String currentStatus, String newStatus) {
    if (currentStatus == newStatus) return false;

    switch (currentStatus) {
      case 'pending':
        return newStatus == 'accepted' ||
            newStatus == 'rejected' ||
            newStatus == 'cancelled';
      case 'accepted':
        return newStatus == 'completed' || newStatus == 'cancelled';
      case 'rejected':
        return false;
      case 'completed':
        return false;
      case 'cancelled':
        return false;
      default:
        return false;
    }
  }
}