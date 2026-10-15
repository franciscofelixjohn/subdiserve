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
  final List<String> _tags = const ['Maintenance', 'Repair', 'Cleaning'];

  Future<void> _openCategoryDialog({
    String? categoryId,
    String? initialTitle,
    String? initialDescription,
    String? initialTag,
  }) async {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDescription);
    String selectedTag = initialTag ?? _tags.first;
    bool isSubmitting = false;
    final isEditing = categoryId != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a category name.')),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);
              try {
                if (isEditing) {
                  await _categoryService.updateCategory(
                    categoryId: categoryId,
                    title: titleController.text,
                    description: descController.text,
                    tag: selectedTag,
                  );
                } else {
                  await _categoryService.addCategory(
                    title: titleController.text,
                    description: descController.text,
                    tag: selectedTag,
                  );
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e')),
                  );
                }
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Edit Category' : 'Add Category',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Category name (e.g. Plumbing)',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Short description',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((tag) {
                      final isSelected = tag == selectedTag;
                      return ChoiceChip(
                        label: Text(tag,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    isSelected ? Colors.white : Colors.white70)),
                        selected: isSelected,
                        onSelected: (_) =>
                            setDialogState(() => selectedTag = tag),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: const Color(0xFF0284C7),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save' : 'Add',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(String categoryId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove "$title"?',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes it from the official list. Providers already using this category keep working normally.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _categoryService.deleteCategory(categoryId);
    }
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Repair':
        return const Color(0xFF38BDF8);
      case 'Cleaning':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Manage Categories',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(),
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Category',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _categoryService.streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                );
              }

              final docs = (snapshot.data?.docs ?? []).toList()
                ..sort((a, b) => (a.data()['title'] ?? '')
                    .toString()
                    .compareTo((b.data()['title'] ?? '').toString()));

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No official categories yet.\nTap "Add Category" to create the first one.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 13),
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = (data['title'] ?? '').toString();
                  final description = (data['description'] ?? '').toString();
                  final tag = (data['tag'] ?? 'Maintenance').toString();
                  final color = _tagColor(tag);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(title,
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(tag,
                                        style: GoogleFonts.poppins(
                                            color: color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(description,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openCategoryDialog(
                            categoryId: doc.id,
                            initialTitle: title,
                            initialDescription: description,
                            initialTag: tag,
                          ),
                          icon: const Icon(Icons.edit_rounded,
                              color: Color(0xFF38BDF8), size: 18),
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(doc.id, title),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 18),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}