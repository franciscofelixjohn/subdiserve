import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookingId;

  final String homeownerId;
  final String homeownerName;
  final String homeownerEmail;

  final String providerId;
  final String providerName;
  final String providerCategory;

  final String service;
  final String address;
  final String notes;

  final DateTime selectedDate;
  final String bookingDate;
  final String bookingTime;

  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool rated;
  final int? ratingGiven;
  final String? ratingComment;
  final String? declineReason;
  final String? cancelReason;
  final List<Map<String, dynamic>> rescheduleHistory;

  BookingModel({
    required this.id,
    required this.bookingId,
    required this.homeownerId,
    required this.homeownerName,
    required this.homeownerEmail,
    required this.providerId,
    required this.providerName,
    required this.providerCategory,
    required this.service,
    required this.address,
    required this.notes,
    required this.selectedDate,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.rated = false,
    this.ratingGiven,
    this.ratingComment,
    this.declineReason,
    this.cancelReason,
    this.rescheduleHistory = const [],
  });

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return BookingModel.fromMap(doc.id, data);
  }

  factory BookingModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime readDateTime(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback ?? DateTime.now();
    }

    String readString(
      dynamic value, {
      String fallback = '',
    }) {
      if (value == null) return fallback;
      final text = value.toString().trim();
      if (text.isEmpty) return fallback;
      return text;
    }

    final selectedDate = readDateTime(
      data['selectedDate'],
      fallback: DateTime.now(),
    );

    final createdAt = readDateTime(
      data['createdAt'],
      fallback: DateTime.now(),
    );

    final updatedAt = readDateTime(
      data['updatedAt'],
      fallback: createdAt,
    );

    final normalizedStatus = readString(
      data['status'],
      fallback: 'pending',
    ).toLowerCase();

    return BookingModel(
      id: id,
      bookingId: readString(
        data['bookingId'],
        fallback: id,
      ),
      homeownerId: readString(data['homeownerId']),
      homeownerName: readString(
        data['homeownerName'],
        fallback: 'Homeowner',
      ),
      homeownerEmail: readString(data['homeownerEmail']),
      providerId: readString(data['providerId']),
      providerName: readString(
        data['providerName'],
        fallback: 'Provider',
      ),
      providerCategory: readString(
        data['providerCategory'],
        fallback: 'General Service',
      ),
      service: readString(
        data['service'],
        fallback: 'Service not specified',
      ),
      address: readString(
        data['address'],
        fallback: 'No address provided',
      ),
      notes: readString(
        data['notes'],
        fallback: '',
      ),
      selectedDate: selectedDate,
      bookingDate: readString(
        data['bookingDate'],
        fallback:
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
      ),
      bookingTime: readString(
        data['bookingTime'],
        fallback: '',
      ),
      status: normalizedStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      rated: data['rated'] == true,
      ratingGiven: data['ratingGiven'] is num
          ? (data['ratingGiven'] as num).toInt()
          : null,
      ratingComment: data['ratingComment']?.toString(),
      declineReason: data['declineReason']?.toString(),
      cancelReason: data['cancelReason']?.toString(),
      rescheduleHistory: (data['rescheduleHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'homeownerId': homeownerId,
      'homeownerName': homeownerName,
      'homeownerEmail': homeownerEmail,
      'providerId': providerId,
      'providerName': providerName,
      'providerCategory': providerCategory,
      'service': service,
      'address': address,
      'notes': notes,
      'selectedDate': Timestamp.fromDate(selectedDate),
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BookingModel copyWith({
    String? id,
    String? bookingId,
    String? homeownerId,
    String? homeownerName,
    String? homeownerEmail,
    String? providerId,
    String? providerName,
    String? providerCategory,
    String? service,
    String? address,
    String? notes,
    DateTime? selectedDate,
    String? bookingDate,
    String? bookingTime,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      homeownerId: homeownerId ?? this.homeownerId,
      homeownerName: homeownerName ?? this.homeownerName,
      homeownerEmail: homeownerEmail ?? this.homeownerEmail,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerCategory: providerCategory ?? this.providerCategory,
      service: service ?? this.service,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      selectedDate: selectedDate ?? this.selectedDate,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // =========================
  // BACKWARD COMPATIBILITY
  // =========================

  String get clientId => homeownerId;
  String get clientName => homeownerName;
  String get serviceName => service;
  String get selectedTime => bookingTime;

  String get userId => homeownerId;
  String get userName => homeownerName;
}