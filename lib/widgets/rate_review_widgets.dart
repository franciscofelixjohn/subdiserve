import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/review_service.dart';

/// A row of star icons showing [rating] out of 5. Purely visual — use
/// [StarRatingPicker] for a tappable version.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 14,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: color,
        );
      }),
    );
  }
}

/// A row of 5 tappable stars for picking a 1-5 rating.
class StarRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= rating;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: const Color(0xFFF59E0B),
            ),
          ),
        );
      }),
    );
  }
}

/// Shows the "Rate this Service" dialog: tappable 5-star picker + an
/// optional comment box. On submit, records the review and updates the
/// provider's running average.
Future<bool> showRateReviewDialog({
  required BuildContext context,
  required String bookingId,
  required String homeownerId,
  required String homeownerName,
  required String providerId,
  required String providerName,
}) async {
  int rating = 0;
  final commentController = TextEditingController();
  bool isSubmitting = false;
  bool submitted = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            if (rating == 0) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Please select a star rating.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              await ReviewService().submitReview(
                bookingId: bookingId,
                homeownerId: homeownerId,
                homeownerName: homeownerName,
                providerId: providerId,
                providerName: providerName,
                rating: rating,
                comment: commentController.text,
              );
              submitted = true;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thanks for your feedback!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to submit rating: $e')),
                );
              }
            } finally {
              setDialogState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            title: Text(
              'Rate $providerName',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How was the service?',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                StarRatingPicker(
                  rating: rating,
                  onChanged: (val) => setDialogState(() => rating = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Leave a comment (optional)...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text('Submit',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return submitted;
}