import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserName(String userId) async {
    try {
      // 1. Hanapin muna sa 'users' collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = data['fullName'] ?? data['name'] ?? data['username'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }

      // 2. Fallback: Kung wala sa users, baka nasa 'providers' collection ang ID
      final providerDoc = await _firestore.collection('providers').doc(userId).get();
      if (providerDoc.exists && providerDoc.data() != null) {
        final data = providerDoc.data()!;
        final name = data['name'] ?? data['fullName'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }
    } catch (e) {
      // Ignore error and return default
    }
    
    return 'User';
  }
}