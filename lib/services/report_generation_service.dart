import 'package:cloud_firestore/cloud_firestore.dart';

/// A single generated report: a title, the date range it covers, a
/// column header list, and the row data underneath. Kept generic so the
/// same export logic (PDF/CSV) works for all 4 report types.
class ReportResult {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> summaryLines;
  final List<String> headers;
  final List<List<String>> rows;

  ReportResult({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.summaryLines,
    required this.headers,
    required this.rows,
  });
}

/// Builds the 4 admin report types (Booking, User Activity, Provider
/// Performance, Ratings) from Firestore data, scoped to a date range.
class ReportGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _inRange(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime? _tsToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // 1. Booking Report
  // ---------------------------------------------------------------------
  Future<ReportResult> generateBookingReport(
    DateTime start,
    DateTime end,
  ) async {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final snapshot = await _firestore.collection('bookings').get();

    final rows = <List<String>>[];
    final statusCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _tsToDate(data['createdAt']);
      if (!_inRange(createdAt, start, endOfDay)) continue;

      final status = (data['status'] ?? 'pending').toString();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      rows.add([
        (data['service'] ?? '').toString(),
        (data['homeownerName'] ?? '').toString(),
        (data['providerName'] ?? '').toString(),
        status,
        createdAt != null ? _fmtDate(createdAt) : '',
      ]);
    }

    final summary = <String>[
      'Total bookings: ${rows.length}',
      ...statusCounts.entries.map((e) => '${e.key}: ${e.value}'),
    ];

    return ReportResult(
      title: 'Booking Report',
      startDate: start,
      endDate: end,
      summaryLines: summary,
      headers: ['Service', 'Homeowner', 'Provider', 'Status', 'Date'],
      rows: rows,
    );
  }

  // ---------------------------------------------------------------------
  // 2. User Activity Report
  // ---------------------------------------------------------------------
  Future<ReportResult> generateUserActivityReport(
    DateTime start,
    DateTime end,
  ) async {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final snapshot = await _firestore.collection('users').get();

    final rows = <List<String>>[];
    int homeowners = 0, providers = 0, restricted = 0, suspended = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _tsToDate(data['createdAt']);

      // If we have a signup date, scope to the range; if not available,
      // include the user anyway so the report isn't empty just because
      // older accounts don't have a createdAt field.
      if (createdAt != null && !_inRange(createdAt, start, endOfDay)) {
        continue;
      }

      final role = (data['role'] ?? 'homeowner').toString();
      final status = (data['status'] ?? 'Active').toString();

      if (role.toLowerCase() == 'provider') {
        providers++;
      } else {
        homeowners++;
      }
      if (status == 'Restricted') restricted++;
      if (status == 'Suspended') suspended++;

      rows.add([
        (data['fullName'] ?? data['name'] ?? '').toString(),
        (data['email'] ?? '').toString(),
        role,
        status,
        createdAt != null ? _fmtDate(createdAt) : 'N/A',
      ]);
    }

    final summary = <String>[
      'Total users: ${rows.length}',
      'Homeowners: $homeowners',
      'Providers: $providers',
      'Restricted: $restricted',
      'Suspended: $suspended',
    ];

    return ReportResult(
      title: 'User Activity Report',
      startDate: start,
      endDate: end,
      summaryLines: summary,
      headers: ['Name', 'Email', 'Role', 'Status', 'Registered'],
      rows: rows,
    );
  }

  // ---------------------------------------------------------------------
  // 3. Provider Performance Report
  // ---------------------------------------------------------------------
  Future<ReportResult> generateProviderPerformanceReport(
    DateTime start,
    DateTime end,
  ) async {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final bookingsSnapshot = await _firestore.collection('bookings').get();

    // providerId -> aggregate counters
    final Map<String, Map<String, dynamic>> byProvider = {};

    for (final doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final completedAt = _tsToDate(data['completedAt']);
      final createdAt = _tsToDate(data['createdAt']);
      final relevantDate = completedAt ?? createdAt;
      if (!_inRange(relevantDate, start, endOfDay)) continue;

      final providerId = (data['providerId'] ?? '').toString();
      if (providerId.isEmpty) continue;

      final providerName = (data['providerName'] ?? 'Unknown').toString();
      final status = (data['status'] ?? '').toString().toLowerCase();

      final entry = byProvider.putIfAbsent(providerId, () => {
            'name': providerName,
            'completed': 0,
            'cancelled': 0,
            'rejected': 0,
          });

      if (status == 'completed') entry['completed'] += 1;
      if (status == 'cancelled') entry['cancelled'] += 1;
      if (status == 'rejected') entry['rejected'] += 1;
    }

    // Pull each provider's overall rating (not date-scoped, since a
    // rating average is a running total, not a per-period figure).
    final providersSnapshot = await _firestore.collection('providers').get();
    final ratingById = <String, Map<String, dynamic>>{};
    for (final doc in providersSnapshot.docs) {
      ratingById[doc.id] = doc.data();
    }

    final rows = <List<String>>[];
    for (final entry in byProvider.entries) {
      final providerId = entry.key;
      final data = entry.value;
      final rating = ratingById[providerId]?['averageRating'];
      final ratingCount = ratingById[providerId]?['ratingCount'] ?? 0;

      rows.add([
        data['name'].toString(),
        data['completed'].toString(),
        data['cancelled'].toString(),
        data['rejected'].toString(),
        rating != null ? (rating as num).toStringAsFixed(1) : 'N/A',
        ratingCount.toString(),
      ]);
    }

    // Sort by most completed jobs first.
    rows.sort((a, b) => int.parse(b[1]).compareTo(int.parse(a[1])));

    final totalCompleted =
        // ignore: avoid_types_as_parameter_names
        byProvider.values.fold<int>(0, (sum, e) => sum + (e['completed'] as int));

    final summary = <String>[
      'Active providers in range: ${byProvider.length}',
      'Total completed jobs: $totalCompleted',
    ];

    return ReportResult(
      title: 'Provider Performance Report',
      startDate: start,
      endDate: end,
      summaryLines: summary,
      headers: [
        'Provider',
        'Completed',
        'Cancelled',
        'Rejected',
        'Avg Rating',
        'Rating Count'
      ],
      rows: rows,
    );
  }

  // ---------------------------------------------------------------------
  // 4. Ratings Report
  // ---------------------------------------------------------------------
  Future<ReportResult> generateRatingsReport(
    DateTime start,
    DateTime end,
  ) async {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final snapshot = await _firestore.collection('reviews').get();

    final rows = <List<String>>[];
    final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    num totalStars = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _tsToDate(data['createdAt']);
      if (!_inRange(createdAt, start, endOfDay)) continue;

      final rating = (data['rating'] ?? 0) as num;
      distribution[rating.toInt()] = (distribution[rating.toInt()] ?? 0) + 1;
      totalStars += rating;

      rows.add([
        (data['providerName'] ?? '').toString(),
        (data['homeownerName'] ?? '').toString(),
        rating.toString(),
        (data['comment'] ?? '').toString(),
        createdAt != null ? _fmtDate(createdAt) : '',
      ]);
    }

    final avg = rows.isEmpty ? 0 : totalStars / rows.length;

    final summary = <String>[
      'Total reviews: ${rows.length}',
      'Average rating: ${avg.toStringAsFixed(2)}',
      for (var star = 5; star >= 1; star--)
        '$star star: ${distribution[star]}',
    ];

    return ReportResult(
      title: 'Ratings Report',
      startDate: start,
      endDate: end,
      summaryLines: summary,
      headers: ['Provider', 'Homeowner', 'Rating', 'Comment', 'Date'],
      rows: rows,
    );
  }
}