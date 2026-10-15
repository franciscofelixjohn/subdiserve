import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kumpletong EmailJS Credentials
  final String serviceId = 'service_9slxsgs';
  final String templateId = 'template_9bezowc';
  final String publicKey = 'YAsAuzgbZHTFz6lSX';

  Future<String?> generateAndSendOtp(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'Email address not found in our records.';
      }

      final userId = querySnapshot.docs.first.id;
      final otpCode = (100000 + Random().nextInt(900000)).toString();
      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5)));

      // I-save ang OTP sa database para sa verification mamaya
      await _firestore.collection('users').doc(userId).update({
        'resetOtp': otpCode,
        'resetOtpExpiresAt': expiresAt,
      });

      // Tawagin ang EmailJS API para magpadala ng email sa personal Gmail ng user
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': cleanEmail,   // Tugma sa {{email}} sa iyong template
            'passcode': otpCode,     // Tugma sa {{passcode}} sa iyong template
          },
        }),
      );

      if (response.statusCode == 200) {
        return null; // Tagumpay! Naipadala na sa Gmail ng user.
      } else {
        return 'Failed to send email: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final data = querySnapshot.docs.first.data();
      final savedOtp = data['resetOtp']?.toString();
      final expiresAt = data['resetOtpExpiresAt'] as Timestamp?;

      if (savedOtp == null || expiresAt == null) return false;

      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      return savedOtp == enteredOtp.trim();
    } catch (e) {
      return false;
    }
  }
}