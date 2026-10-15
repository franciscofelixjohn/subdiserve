import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/suspension_service.dart';

/// Shows the "Restrict Account" dialog: admin must leave a reason. The
/// account stays usable for 7 days and auto-escalates to full Suspended
/// if the user doesn't appeal in time.
Future<bool> showRestrictAccountDialog({
  required BuildContext context,
  required String userId,
  required String userName,
}) async {
  final reasonController = TextEditingController();
  bool isSubmitting = false;
  bool applied = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> confirm() async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                    content: Text('Please enter a reason for restricting.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              await SuspensionService().restrictUser(
                userId: userId,
                reason: reasonController.text,
              );
              applied = true;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '$userName is now Restricted (usable for 7 days; auto-suspends if they don\'t appeal).'),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to restrict: $e')),
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
                  color: Colors.orangeAccent.withValues(alpha: 0.2)),
            ),
            title: Text(
              'Restrict $userName?',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The account stays usable for 7 days. If they don\'t submit an appeal within that time, it automatically becomes fully Suspended.',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Reason for restricting (required)...',
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
                onPressed: isSubmitting ? null : confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
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
                    : Text('Restrict',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return applied;
}

/// Shows the "Suspend Account" dialog: admin must leave a reason. The
/// account becomes immediately and fully locked out — usable only again
/// once an appeal is submitted and approved by an admin.
Future<bool> showSuspendAccountDialog({
  required BuildContext context,
  required String userId,
  required String userName,
}) async {
  final reasonController = TextEditingController();
  bool isSubmitting = false;
  bool applied = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> confirm() async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                    content: Text('Please enter a reason for suspension.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              await SuspensionService().suspendUser(
                userId: userId,
                reason: reasonController.text,
              );
              applied = true;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '$userName has been Suspended. The account is fully locked out until an appeal is approved.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to suspend: $e')),
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
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
            ),
            title: Text(
              'Suspend $userName?',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This immediately and fully locks the account out. It can only be restored once they submit an appeal and you approve it.',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Reason for suspension (required)...',
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
                onPressed: isSubmitting ? null : confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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
                    : Text('Suspend',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return applied;
}

/// Shows the "Activate Account" dialog: admin must leave a note
/// explaining why the account is being reactivated.
Future<bool> showActivateAccountDialog({
  required BuildContext context,
  required String userId,
  required String userName,
}) async {
  final noteController = TextEditingController();
  bool isSubmitting = false;
  bool applied = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> confirm() async {
            if (noteController.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                    content: Text('Please enter a note for reactivating.')),
              );
              return;
            }

            setDialogState(() => isSubmitting = true);
            try {
              await SuspensionService().activateUser(
                userId: userId,
                note: noteController.text,
              );
              applied = true;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$userName has been reactivated.'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to activate: $e')),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.2)),
            ),
            title: Text(
              'Activate $userName?',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Note for reactivating this account (required)...',
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
                    : Text('Activate',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  return applied;
}

/// Shows the full appeal history for an account.
Future<void> showAppealHistoryDialog({
  required BuildContext context,
  required String userId,
  required String userName,
}) async {
  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        ),
        title: Text(
          '$userName\'s Appeal History',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        content: SizedBox(
          width: 400,
          height: 320,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: SuspensionService().streamAppealHistory(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                );
              }

              final docs = (snapshot.data?.docs ?? []).toList()
                ..sort((a, b) {
                  final aTs = a.data()['submittedAt'];
                  final bTs = b.data()['submittedAt'];
                  final aDate = aTs is Timestamp
                      ? aTs.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = bTs is Timestamp
                      ? bTs.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No appeals submitted by this account yet.',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 12),
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final message = (data['message'] ?? '').toString();
                  final statusAt =
                      (data['accountStatusAtSubmission'] ?? '').toString();
                  final ts = data['submittedAt'];
                  final dateStr = ts is Timestamp
                      ? '${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}'
                      : '';

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'While: $statusAt',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(dateStr,
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(message,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
        ],
      );
    },
  );
}