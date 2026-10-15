import 'package:cloud_firestore/cloud_firestore.dart';

/// Lets an admin curate the official list of service categories shown
/// to homeowners (e.g. "Plumbing", "House Cleaning"). Homeowner/provider
/// screens read this collection as the base list, in addition to
/// whatever categories individual providers have listed themselves.
class CategoryService {
  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCategories() {
    return _categoriesRef.snapshots();
  }

  Future<void> addCategory({
    required String title,
    required String description,
    required String tag, // Maintenance | Repair | Cleaning
  }) async {
    await _categoriesRef.add({
      'title': title.trim(),
      'description': description.trim(),
      'tag': tag,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String categoryId,
    required String title,
    required String description,
    required String tag,
  }) async {
    await _categoriesRef.doc(categoryId).update({
      'title': title.trim(),
      'description': description.trim(),
      'tag': tag,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }
}