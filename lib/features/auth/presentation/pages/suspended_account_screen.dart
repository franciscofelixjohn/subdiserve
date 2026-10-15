import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/suspension_service.dart';
import 'login_screen.dart';

/// Shown after a tier-3-suspended user's credentials are verified,
/// instead of letting them into the app. Firebase Auth has already been
/// signed out by this point. Styled like a "Banned account" screen: a
/// summary card, then an appeal action.
class SuspendedAccountScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String reason;
  final String appealStatus; // 'none' | 'pending' | 'reviewed'

  const SuspendedAccountScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.reason,
    required this.appealStatus,
  });

  @override
  State<SuspendedAccountScreen> createState() =>
      _SuspendedAccountScreenState();
}

class _SuspendedAccountScreenState extends State<SuspendedAccountScreen> {
  final SuspensionService _suspensionService = SuspensionService();
  bool _appealJustSubmitted = false;

  Future<void> _openAppealDialog() async {
    final appealController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> send() async {
              if (appealController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Please explain your appeal.')),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);
              try {
                await _suspensionService.submitAppeal(
                  userId: widget.userId,
                  message: appealController.text,
                  accountStatusAtSubmission: 'Suspended',
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) setState(() => _appealJustSubmitted = true);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to submit: $e')),
                  );
                }
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF15161B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              title: Text('Request appeal',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explain why you believe this suspension should be lifted.',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: appealController,
                    maxLines: 4,
                    maxLength: 1000,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Additional info...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ),
                  ),
                  Text(
                    'By selecting Send, you confirm that this information is true and that you\'re only sending one appeal about this decision.',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 10),
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
                  onPressed: isSubmitting ? null : send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Send',
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

  @override
  Widget build(BuildContext context) {
    final appealPending =
        _appealJustSubmitted || widget.appealStatus == 'pending';
    final appealReviewed = widget.appealStatus == 'reviewed';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF15161B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block_rounded,
                            color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        Text('Suspended',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We suspended ${widget.userName}\'s account because of repeated rule-breaking. Your account will remain locked until an appeal is submitted and approved by an admin.',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Text('What happened',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason:',
                              style: GoogleFonts.poppins(
                                  color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            widget.reason.isNotEmpty
                                ? widget.reason
                                : 'Repeated policy violations',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Text('Admin note:',
                              style: GoogleFonts.poppins(
                                  color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            'You need to submit an appeal for an admin to review before access to this account can be restored.',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (appealReviewed) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Your appeal has been reviewed. Please try logging in again.',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ] else if (appealPending) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Appeal submitted. Awaiting admin review.',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _openAppealDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Send appeal',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text('Back to Login',
                            style:
                                GoogleFonts.poppins(color: Colors.white54)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}