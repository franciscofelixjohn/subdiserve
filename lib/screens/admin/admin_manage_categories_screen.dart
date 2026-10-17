
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/category_service.dart';

class AdminManageCategoriesScreen extends StatefulWidget {
  const AdminManageCategoriesScreen({super.key});

  @override
  State<AdminManageCategoriesScreen> createState() =>
      _AdminManageCategoriesScreenState();
}

class _AdminManageCategoriesScreenState
    extends State<AdminManageCategoriesScreen> {
  final CategoryService _categoryService = CategoryService();

  final List<String> _tags = const [
    'Maintenance',
    'Repair',
    'Cleaning',
  ];

  bool _seedingStarted = false;

  @override
  void initState() {
    super.initState();
    _ensureDefaults();
  }

  Future<void> _ensureDefaults() async {
    if (_seedingStarted) return;
    _seedingStarted = true;

    try {
      await _categoryService.ensureDefaultCategories();
    } catch (e) {
      debugPrint('Unable to initialize categories: $e');
    }
  }

  Future<void> _openCategoryDialog({
    String? categoryId,
    String? initialTitle,
    String? initialDescription,
    String? initialTag,
  }) async {
    final titleController = TextEditingController(
      text: initialTitle ?? '',
    );

    final descriptionController = TextEditingController(
      text: initialDescription ?? '',
    );

    String selectedTag = _tags.contains(initialTag)
        ? initialTag!
        : 'Maintenance';

    bool isSubmitting = false;
    final isEditing = categoryId != null;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> submit() async {
                final title = titleController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a category name.'),
                    ),
                  );
                  return;
                }

                setDialogState(() => isSubmitting = true);

                try {
                  if (isEditing) {
                    await _categoryService.updateCategory(
                      categoryId: categoryId,
                      title: title,
                      description: descriptionController.text,
                      tag: selectedTag,
                    );
                  } else {
                    await _categoryService.addCategory(
                      title: title,
                      description: descriptionController.text,
                      tag: selectedTag,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to save category: ${e.toString().replaceFirst('Bad state: ', '')}',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                }
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  isEditing ? 'Edit Category' : 'Add Category',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g. Plumbing, Barber',
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                          ),
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Category Type',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _tags.map((tag) {
                          final selected = selectedTag == tag;

                          return ChoiceChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (_) {
                              setDialogState(() {
                                selectedTag = tag;
                              });
                            },
                            backgroundColor: const Color(0xFF172338),
                            selectedColor: const Color(0xFF0284C7),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add Category'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _confirmDelete(
    String categoryId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          'Remove "$title"?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This removes the category from the official list. '
          'Existing provider profiles will not be deleted.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _categoryService.deleteCategory(categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$title" removed from official categories.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to remove category: $e')),
        );
      }
    }
  }

  Future<void> _approveProviderService(String title) async {
    try {
      await _categoryService.addCategory(
        title: title,
        description: 'Service submitted by a registered service provider.',
        tag: _guessTag(title),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$title" added to official categories.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('already exists')
                ? '"$title" is already an official category.'
                : 'Unable to add category: $e',
          ),
        ),
      );
    }
  }

  String _guessTag(String title) {
    final value = title.toLowerCase();

    if (value.contains('clean')) return 'Cleaning';

    if (value.contains('repair') ||
        value.contains('carpent') ||
        value.contains('plumb') ||
        value.contains('electric') ||
        value.contains('construction')) {
      return 'Repair';
    }

    return 'Maintenance';
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Repair':
        return const Color(0xFF8B5CF6);
      case 'Cleaning':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _officialCategoryCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final tag = (data['tag'] ?? 'Maintenance').toString();
    final color = _tagColor(tag);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF172338),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tag == 'Cleaning'
                  ? Icons.cleaning_services_rounded
                  : tag == 'Repair'
                      ? Icons.handyman_rounded
                      : Icons.home_repair_service_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Official category',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF34D399),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit category',
            onPressed: () => _openCategoryDialog(
              categoryId: doc.id,
              initialTitle: title,
              initialDescription: description,
              initialTag: tag,
            ),
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Delete category',
            onPressed: () => _confirmDelete(doc.id, title),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerServiceCard(
    String title,
    int providerCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFFF59E0B),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$providerCount provider(s) offering this service',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provider-submitted • Not official yet',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFBBF24),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _approveProviderService(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manage Categories',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: Text(
          'Add Category',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _categoryService.streamCategories(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load official categories.\n${categorySnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (!categorySnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF38BDF8),
                ),
              );
            }

            final categoryDocs = categorySnapshot.data!.docs.toList()
              ..sort(
                (a, b) => (a.data()['title'] ?? '')
                    .toString()
                    .toLowerCase()
                    .compareTo(
                      (b.data()['title'] ?? '')
                          .toString()
                          .toLowerCase(),
                    ),
              );

            final officialNames = categoryDocs
                .map(
                  (doc) => _categoryService.normalizeTitle(
                    (doc.data()['title'] ?? '').toString(),
                  ),
                )
                .toSet();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _categoryService.streamProviders(),
              builder: (context, providerSnapshot) {
                if (providerSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load provider services.\n${providerSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!providerSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF38BDF8),
                    ),
                  );
                }

                final Map<String, Map<String, dynamic>> submittedServices = {};

                for (final providerDoc in providerSnapshot.data!.docs) {
                  final provider = providerDoc.data();

                  final serviceNames = <String>{
                    (provider['service'] ?? '').toString().trim(),
                    (provider['serviceType'] ?? '').toString().trim(),
                  };

                  for (final serviceName in serviceNames) {
                    if (serviceName.isEmpty) continue;

                    final normalized =
                        _categoryService.normalizeTitle(serviceName);

                    if (normalized.isEmpty ||
                        officialNames.contains(normalized)) {
                      continue;
                    }

                    final entry = submittedServices.putIfAbsent(
                      normalized,
                      () => {
                        'title': serviceName,
                        'providerIds': <String>{},
                      },
                    );

                    (entry['providerIds'] as Set<String>)
                        .add(providerDoc.id);
                  }
                }

                final pendingServices = submittedServices.values.toList()
                  ..sort(
                    (a, b) => (a['title'] as String)
                        .toLowerCase()
                        .compareTo((b['title'] as String).toLowerCase()),
                  );

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _sectionTitle(
                      'Official Categories',
                      'Services approved for the SubdiServe system.',
                    ),
                    if (categoryDocs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Setting up the default categories...',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ...categoryDocs.map(_officialCategoryCard),

                    const SizedBox(height: 18),

                    _sectionTitle(
                      'New Provider Services',
                      'Services automatically collected from provider registrations.',
                    ),

                    if (pendingServices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'No new provider services waiting for review.',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ...pendingServices.map((service) {
                        final providerIds =
                            service['providerIds'] as Set<String>;

                        return _providerServiceCard(
                          service['title'] as String,
                          providerIds.length,
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
