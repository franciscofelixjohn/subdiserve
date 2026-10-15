import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/progress_service.dart';

/// Shows the "Work Progress" timeline for a booking: a photo, a day
/// label (e.g. "Day 1"), a short note, and a timestamp for each update
/// the provider has posted.
///
/// Pass [showAddButton]: true (provider view only) to let the current
/// user post new updates. Homeowners and admins should pass false — they
/// only ever view the timeline.
class ProgressTimeline extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final bool showAddButton;

  const ProgressTimeline({
    super.key,
    required this.bookingId,
    required this.providerId,
    this.showAddButton = false,
  });

  @override
  State<ProgressTimeline> createState() => _ProgressTimelineState();
}

class _ProgressTimelineState extends State<ProgressTimeline> {
  final ProgressService _progressService = ProgressService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _openAddUpdateSheet() async {
    XFile? pickedImage;
    final dayController = TextEditingController();
    final noteController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickImage() async {
              final file = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1000,
                imageQuality: 55,
              );
              if (file != null) {
                setSheetState(() => pickedImage = file);
              }
            }

            Future<void> save() async {
              if (dayController.text.trim().isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a day label, e.g. "Day 1"'),
                  ),
                );
                return;
              }

              setSheetState(() => isSaving = true);

              try {
                String? photoBase64;
                if (pickedImage != null) {
                  final bytes = await pickedImage!.readAsBytes();
                  photoBase64 = base64Encode(bytes);
                }

                await _progressService.addProgressUpdate(
                  bookingId: widget.bookingId,
                  providerId: widget.providerId,
                  dayLabel: dayController.text,
                  note: noteController.text,
                  photoBase64: photoBase64,
                );

                if (sheetContext.mounted) Navigator.pop(sheetContext);
              } catch (e) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text('Failed to post update: $e')),
                  );
                }
              } finally {
                setSheetState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B192C),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Progress Update',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: FutureBuilder<Uint8List>(
                                  future: pickedImage!.readAsBytes(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF38BDF8),
                                        ),
                                      );
                                    }
                                    return Image.memory(snap.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity);
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_rounded,
                                      color: Color(0xFF38BDF8), size: 28),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to attach a photo',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: dayController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Day label (e.g. Day 1, Day 2, Final Day)',
                        hintStyle:
                            GoogleFonts.poppins(color: Colors.white38),
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
                      controller: noteController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'What was done today? (optional but recommended)',
                        hintStyle:
                            GoogleFonts.poppins(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Post Update',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  $h:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Work Progress',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.showAddButton)
              TextButton.icon(
                onPressed: _openAddUpdateSheet,
                icon: const Icon(Icons.add_a_photo_rounded,
                    size: 16, color: Color(0xFF38BDF8)),
                label: Text(
                  'Add Update',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _progressService.streamProgressUpdates(widget.bookingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  widget.showAddButton
                      ? 'No progress updates yet. Post one to keep your client informed.'
                      : 'The provider hasn\'t posted any progress updates yet.',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 12),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final isLast = index == docs.length - 1;
                final photoBase64 = data['photoBase64'] as String?;
                final dayLabel =
                    (data['dayLabel'] ?? 'Update').toString();
                final note = (data['note'] ?? '').toString();
                final ts = data['createdAt'] as Timestamp?;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dayLabel,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(ts),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                if (photoBase64 != null &&
                                    photoBase64.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(photoBase64),
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    note,
                                    style: GoogleFonts.poppins(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}