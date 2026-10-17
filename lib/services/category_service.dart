
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');

  final CollectionReference<Map<String, dynamic>> _providersRef =
      FirebaseFirestore.instance.collection('providers');

  static const List<Map<String, String>> defaultCategories = [
    {
      'id': 'carpenter',
      'title': 'Carpenter',
      'description': 'Carpentry, woodwork, and furniture repairs.',
      'tag': 'Repair',
    },
    {
      'id': 'cleaning',
      'title': 'Cleaning',
      'description': 'Home cleaning and general cleaning services.',
      'tag': 'Cleaning',
    },
  ];

  String normalizeTitle(String title) {
    return title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCategories() {
    return _categoriesRef.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamProviders() {
    return _providersRef.snapshots();
  }

  /// Creates the initial official categories if they do not exist.
  /// Existing categories are preserved.
  Future<void> ensureDefaultCategories() async {
    final snapshot = await _categoriesRef.get();

    final existingTitles = snapshot.docs
        .map((doc) => normalizeTitle(
              (doc.data()['title'] ?? '').toString(),
            ))
        .where((title) => title.isNotEmpty)
        .toSet();

    final batch = FirebaseFirestore.instance.batch();
    var hasChanges = false;

    for (final category in defaultCategories) {
      final title = category['title']!;

      if (existingTitles.contains(normalizeTitle(title))) {
        continue;
      }

      final ref = _categoriesRef.doc(category['id']);

      batch.set(ref, {
        'title': title,
        'description': category['description'],
        'tag': category['tag'],
        'source': 'official',
        'createdAt': FieldValue.serverTimestamp(),
      });

      existingTitles.add(normalizeTitle(title));
      hasChanges = true;
    }

    if (hasChanges) {
      await batch.commit();
    }
  }

  /// Adds a category only when its title does not already exist.
  Future<void> addCategory({
    required String title,
    required String description,
    required String tag,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final snapshot = await _categoriesRef.get();
    final normalized = normalizeTitle(cleanTitle);

    final alreadyExists = snapshot.docs.any((doc) {
      return normalizeTitle(
            (doc.data()['title'] ?? '').toString(),
          ) ==
          normalized;
    });

    if (alreadyExists) {
      throw StateError('"$cleanTitle" already exists in categories.');
    }

    await _categoriesRef.add({
      'title': cleanTitle,
      'description': cleanDescription,
      'tag': tag,
      'source': 'official',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String categoryId,
    required String title,
    required String description,
    required String tag,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final snapshot = await _categoriesRef.get();
    final normalized = normalizeTitle(cleanTitle);

    final duplicate = snapshot.docs.any((doc) {
      return doc.id != categoryId &&
          normalizeTitle(
                (doc.data()['title'] ?? '').toString(),
              ) ==
              normalized;
    });

    if (duplicate) {
      throw StateError('"$cleanTitle" already exists in categories.');
    }

    await _categoriesRef.doc(categoryId).update({
      'title': cleanTitle,
      'description': description.trim(),
      'tag': tag,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }
}
