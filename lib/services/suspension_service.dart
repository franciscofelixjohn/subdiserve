import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

/// Handles account restriction/suspension for ANY account type
/// (homeowner or provider) stored in the top-level `users` collection,
/// and mirrors the status onto the matching `providers/{uid}` doc (if
/// one exists) so provider-facing screens can show a badge without
/// extra lookups.
///
/// The admin has two distinct actions:
///   - Restrict: soft action. Status becomes 'Restricted'. The account
///     stays fully usable for 7 days. If the user doesn't submit an
///     appeal before the 7 days are up, the account automatically
///     escalates to 'Suspended'. If they do submit an appeal in time,
///     it stays 'Restricted' pending admin review (no auto-escalation
///     while an appeal is pending).
///   - Suspend: hard action. Status becomes 'Suspended' immediately.
///     The account is fully locked out and can only be restored by
///     submitting an appeal that an admin approves.
///
/// Fields on `users/{uid}`:
///   status                  : 'Active' | 'Restricted' | 'Suspended'
///   suspensionCount         : how many times this account has been flagged (stats only)
///   suspensionReason        : latest note the admin left
///   suspendedAt             : when the current restriction/suspension started
///   restrictionEndDate      : when a 'Restricted' status auto-escalates (null for Suspended)
///   appealStatus            : 'none' | 'pending' | 'reviewed'
///   appealMessage           : the user's latest appeal message
///   appealSubmittedAt       : when the latest appeal was submitted
///   lastActivationNote      : latest note the admin left when reactivating
///   lastActivatedAt         : when the account was last reactivated
///
/// All appeals (not just the latest) are additionally logged to the
/// `users/{uid}/appeals` subcollection so admins can see a full history.
class SuspensionService {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference<Map<String, dynamic>> _providersRef =
      FirebaseFirestore.instance.collection('providers');
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> _appealsRef(String userId) {
    return _usersRef.doc(userId).collection('appeals');
  }

  Future<void> _mirrorToProviderDoc(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final providerDoc = await _providersRef.doc(userId).get();
      if (providerDoc.exists) {
        await _providersRef.doc(userId).update(fields);
      }
    } catch (_) {
      // Not a provider account, or doc doesn't exist yet — ignore.
    }
  }

  /// Soft action: restricts the account for 7 days. Still fully usable
  /// during that time; auto-escalates to Suspended if unaddressed.
  Future<void> restrictUser({
    required String userId,
    required String reason,
  }) async {
    final doc = await _usersRef.doc(userId).get();
    final currentCount = (doc.data()?['suspensionCount'] ?? 0) as int;

    final now = DateTime.now();
    final fields = {
      'status': 'Restricted',
      'suspensionCount': currentCount + 1,
      'suspensionReason': reason.trim(),
      'suspendedAt': Timestamp.fromDate(now),
      'restrictionEndDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
      'appealStatus': 'none',
      'appealMessage': null,
    };

    await _usersRef.doc(userId).update(fields);
    await _mirrorToProviderDoc(userId, fields);

    await _notificationService.createNotification(
      userId: userId,
      title: 'Account Restricted',
      body: 'Your account has been restricted: $reason. You can still use it, but it may become suspended if you don\'t appeal.',
      type: 'account',
    );
  }

  /// Hard action: suspends the account immediately. Fully locked out
  /// until an appeal is submitted and approved by an admin.
  Future<void> suspendUser({
    required String userId,
    required String reason,
  }) async {
    final doc = await _usersRef.doc(userId).get();
    final currentCount = (doc.data()?['suspensionCount'] ?? 0) as int;

    final now = DateTime.now();
    final fields = {
      'status': 'Suspended',
      'suspensionCount': currentCount + 1,
      'suspensionReason': reason.trim(),
      'suspendedAt': Timestamp.fromDate(now),
      'restrictionEndDate': null,
      'appealStatus': 'none',
      'appealMessage': null,
    };

    await _usersRef.doc(userId).update(fields);
    await _mirrorToProviderDoc(userId, fields);

    await _notificationService.createNotification(
      userId: userId,
      title: 'Account Suspended',
      body: 'Your account has been suspended: $reason. Submit an appeal to restore access.',
      type: 'account',
    );
  }

  /// Internal: used only by the auto-escalation check below.
  Future<void> _autoEscalateToSuspended(String userId) async {
    final fields = {
      'status': 'Suspended',
      'suspensionReason': 'Restriction period expired without an appeal.',
      'suspendedAt': Timestamp.fromDate(DateTime.now()),
      'restrictionEndDate': null,
      'appealStatus': 'none',
      'appealMessage': null,
    };
    await _usersRef.doc(userId).update(fields);
    await _mirrorToProviderDoc(userId, fields);
  }

  /// Fully reactivates an account — used for a manual admin override, for
  /// lifting a 'Restricted' status early, or for approving a submitted
  /// appeal on a 'Suspended' account.
  Future<void> activateUser({
    required String userId,
    required String note,
  }) async {
    final fields = {
      'status': 'Active',
      'restrictionEndDate': null,
      'appealStatus': 'reviewed',
      'lastActivationNote': note.trim(),
      'lastActivatedAt': Timestamp.fromDate(DateTime.now()),
      'lastActivationNoteSeen': false,
    };

    await _usersRef.doc(userId).update(fields);
    await _mirrorToProviderDoc(userId, fields);

    await _notificationService.createNotification(
      userId: userId,
      title: 'Account Reactivated',
      body: note.trim().isNotEmpty
          ? 'Your account is active again. Note: $note'
          : 'Your account is active again.',
      type: 'account',
    );
  }

  /// Marks the latest reactivation note as seen so it doesn't keep
  /// popping up on every future login.
  Future<void> markActivationNoteSeen(String userId) async {
    await _usersRef.doc(userId).update({'lastActivationNoteSeen': true});
  }

  /// Called by a Restricted or Suspended user to submit an appeal for
  /// admin review. Logs to the appeals history subcollection AND updates
  /// the quick-access fields on the user doc.
  Future<void> submitAppeal({
    required String userId,
    required String message,
    required String accountStatusAtSubmission,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());

    await _usersRef.doc(userId).update({
      'appealStatus': 'pending',
      'appealMessage': message.trim(),
      'appealSubmittedAt': now,
    });

    await _appealsRef(userId).add({
      'message': message.trim(),
      'status': 'pending',
      'accountStatusAtSubmission': accountStatusAtSubmission,
      'submittedAt': now,
    });
  }

  /// Full appeal history for an account (does NOT use .orderBy() to
  /// avoid needing a composite index — sort client-side instead).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAppealHistory(
    String userId,
  ) {
    return _appealsRef(userId).snapshots();
  }

  /// Checks a user's current status and:
  ///   - auto-escalates 'Restricted' -> 'Suspended' if the 7-day window
  ///     has passed AND no appeal is currently pending.
  ///   - leaves 'Suspended' alone (never auto-lifts; needs an approved
  ///     appeal).
  /// Returns the up-to-date user data.
  Future<Map<String, dynamic>?> checkAndAutoLift(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    final data = doc.data();
    if (data == null) return null;

    final status = (data['status'] ?? 'Active').toString();
    if (status != 'Restricted') return data; // Active or Suspended: no-op

    final appealStatus = (data['appealStatus'] ?? 'none').toString();
    if (appealStatus == 'pending') return data; // awaiting admin review

    final endTimestamp = data['restrictionEndDate'];
    if (endTimestamp is Timestamp &&
        DateTime.now().isAfter(endTimestamp.toDate())) {
      await _autoEscalateToSuspended(userId);
      final refreshed = await _usersRef.doc(userId).get();
      return refreshed.data();
    }

    return data;
  }
}