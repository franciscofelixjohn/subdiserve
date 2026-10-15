import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label = status.toUpperCase();

    // Determine color based on status
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        backgroundColor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
        textColor = const Color(0xFF38BDF8);
        break;
      case 'completed':
        backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        break;
      case 'pending':
      default:
        backgroundColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFF59E0B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}