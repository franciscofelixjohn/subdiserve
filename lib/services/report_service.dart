import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles homeowner -> admin reports about a provider on a specific
/// booking (e.g. no-show, poor quality work, unsafe behavior, etc).
/// Reports live in a single top-level 'reports' collection so admins can
/// review them platform-wide, or filtered to one booking.
class ReportService {
  final CollectionReference<Map<String, dynamic>> _reportsRef =
      FirebaseFirestore.instance.collection('reports');

  Future<void> submitReport({
    required String bookingId,
    required String homeownerId,
    required String homeownerName,
    required String providerId,
    required String providerName,
    required String reason,
    required String description,
  }) async {
    await _reportsRef.add({
      'bookingId': bookingId,
      'homeownerId': homeownerId,
      'homeownerName': homeownerName,
      'providerId': providerId,
      'providerName': providerName,
      'reason': reason,
      'description': description.trim(),
      'status': 'pending', // pending -> reviewed -> resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// All reports tied to one booking (used by the admin "Manage" screen).
  /// Intentionally does NOT use .orderBy() here, since combining it with
  /// .where('bookingId', ...) on a different field requires a Firestore
  /// composite index. Sorting is done client-side instead (see
  /// admin_booking_manage_screen.dart) so this works immediately without
  /// needing to create an index in the Firebase console.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReportsForBooking(
    String bookingId,
  ) {
    return _reportsRef.where('bookingId', isEqualTo: bookingId).snapshots();
  }

  /// All reports platform-wide, newest first (handy for a future admin
  /// "Reports" inbox screen).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllReports() {
    return _reportsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    await _reportsRef.doc(reportId).update({'status': status});
  }
}