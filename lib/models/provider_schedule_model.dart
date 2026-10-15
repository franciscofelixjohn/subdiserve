import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderScheduleModel {
  final String providerId;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final Timestamp? updatedAt;

  ProviderScheduleModel({
    required this.providerId,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory ProviderScheduleModel.fromMap(Map<String, dynamic> map) {
    return ProviderScheduleModel(
      providerId: map['providerId'] ?? '',
      availableDays: List<String>.from(map['availableDays'] ?? []),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      updatedAt: map['updatedAt'],
    );
  }
}