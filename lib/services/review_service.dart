import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Handles the ratings & feedback system: a homeowner rates (1-5 stars)
/// and leaves a comment for a provider once a booking is 'completed'.
///
/// Individual reviews are logged to a top-level 'reviews' collection so
/// they can be listed on a provider's profile. The provider's running
/// average is kept on `providers/{providerId}` (and mirrored to
/// `users/{providerId}`) as `ratingTotal`, `ratingCount`, and
/// `averageRating`, updated inside a transaction so concurrent
/// submissions never corrupt the average.
class ReviewService {
  final CollectionReference<Map<String, dynamic>> _reviewsRef =
      FirebaseFirestore.instance.collection('reviews');
  final CollectionReference<Map<String, dynamic>> _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');
  final CollectionReference<Map<String, dynamic>> _providersRef =
      FirebaseFirestore.instance.collection('providers');
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');
  final NotificationService _notificationService = NotificationService();

  /// Submits a new review for a completed booking. Updates the
  /// provider's average rating atomically and marks the booking as
  /// rated so the homeowner can't submit a second review for it.
  Future<void> submitReview({
    required String bookingId,
    required String homeownerId,
    required String homeownerName,
    required String providerId,
    required String providerName,
    required int rating,
    required String comment,
  }) async {
    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final providerDoc = await transaction.get(_providersRef.doc(providerId));
      final currentCount =
          (providerDoc.data()?['ratingCount'] ?? 0) as int;
      final currentTotal =
          ((providerDoc.data()?['ratingTotal'] ?? 0) as num).toDouble();

      final newCount = currentCount + 1;
      final newTotal = currentTotal + rating;
      final newAverage = newTotal / newCount;

      final aggregateFields = {
        'ratingCount': newCount,
        'ratingTotal': newTotal,
        'averageRating': newAverage,
      };

      if (providerDoc.exists) {
        transaction.update(_providersRef.doc(providerId), aggregateFields);
      } else {
        transaction.set(_providersRef.doc(providerId), aggregateFields,
            SetOptions(merge: true));
      }

      transaction.set(
        _usersRef.doc(providerId),
        aggregateFields,
        SetOptions(merge: true),
      );

      transaction.set(_reviewsRef.doc(), {
        'bookingId': bookingId,
        'homeownerId': homeownerId,
        'homeownerName': homeownerName,
        'providerId': providerId,
        'providerName': providerName,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': now,
      });

      transaction.update(_bookingsRef.doc(bookingId), {
        'rated': true,
        'ratingGiven': rating,
        'ratingComment': comment.trim(),
      });
    });

    await _notificationService.createNotification(
      userId: providerId,
      title: 'New Rating Received',
      body: '$homeownerName gave you a $rating-star rating.',
      type: 'rating',
      bookingId: bookingId,
    );
  }

  /// All reviews for a provider (does NOT use .orderBy() to avoid
  /// needing a composite index — sort client-side instead).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReviewsForProvider(
    String providerId,
  ) {
    return _reviewsRef.where('providerId', isEqualTo: providerId).snapshots();
  }

  /// Live aggregate rating for a provider (average + count).
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamProviderRating(
    String providerId,
  ) {
    return _providersRef.doc(providerId).snapshots();
  }
}