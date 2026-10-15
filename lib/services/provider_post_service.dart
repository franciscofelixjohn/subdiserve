import 'package:cloud_firestore/cloud_firestore.dart';


class ProviderPostService {
  final CollectionReference<Map<String, dynamic>> _postsRef =
      FirebaseFirestore.instance.collection('provider_posts');

  /// Creates a new portfolio post or completed project for the service provider.
  Future<void> createPost({
    required String providerId,
    required String providerName,
    required String category,
    required String imageUrl,
    required String caption,
    required String priceRange,
  }) async {
    await _postsRef.add({
      'providerId': providerId,
      'providerName': providerName,
      'category': category,
      'imageUrl': imageUrl,
      'caption': caption.trim(),
      'priceRange': priceRange.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all posts for the Marketplace / Feed view (Visible to Homeowners).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllPosts() {
    return _postsRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// Streams posts belonging to a specific provider (For Profile Portfolio view).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProviderPosts(String providerId) {
    return _postsRef
        .where('providerId', isEqualTo: providerId)
        .snapshots();
  }

  /// Deletes a specific portfolio post.
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }
}