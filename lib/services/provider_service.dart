import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_model.dart';

class ProviderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all registered providers from users collection
  Stream<List<ProviderModel>> getProviders() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProviderModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}