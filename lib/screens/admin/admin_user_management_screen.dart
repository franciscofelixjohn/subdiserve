import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/suspension_dialogs.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return '';
  }

  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final name = data['fullName'] ?? data['name'] ?? 'Unknown User';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'homeowner';
    final status = data['status'] ?? 'Active';
    final phone = data['phone'] ?? data['phoneNumber'] ?? 'Not provided';
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]
        : 'Recent';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C2340),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Email', email),
            const SizedBox(height: 12),
            _buildDialogRow('Role', role.toUpperCase()),
            const SizedBox(height: 12),
            _buildDialogRow('Status', status),
            const SizedBox(height: 12),
            _buildDialogRow('Phone', phone),
            const SizedBox(height: 12),
            _buildDialogRow('Joined', createdAt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'restricted':
        return Colors.orangeAccent;
      case 'suspended':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    String userId,
    String name,
    String role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0C2340),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Delete $name\'s account?',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'This permanently removes their profile data from the app. This cannot be undone. '
          'Note: this only removes their app data — their login credential itself must be '
          'removed separately (requires a backend/Cloud Function).',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (role == 'provider') {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(userId)
            .delete();
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name\'s account data has been deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        title: Text(
          'User Management',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020408), Color(0xFF061021), Color(0xFF0B192C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registered Users',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage homeowners and service providers',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isNotEqualTo: 'admin')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No other users found.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      final allDocs = snapshot.data!.docs;
                      final docs = _searchQuery.isEmpty
                          ? allDocs
                          : allDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['fullName'] ?? data['name'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return name.contains(_searchQuery);
                            }).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No other users found.'
                                : 'No users match "$_searchQuery".',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final userId = docs[index].id;
                          final name = data['fullName'] ?? data['name'] ?? 'Unknown User';
                          final email = data['email'] ?? 'No email';
                          final role = data['role'] ?? 'homeowner';
                          final formattedRole = role == 'provider'
                              ? 'Service Provider'
                              : 'Homeowner';
                          final status = data['status'] ?? 'Active';
                          final statusColor = getStatusColor(status);
                          final suspensionReason =
                              (data['suspensionReason'] ?? '').toString();
                          final restrictionEndDate = data['restrictionEndDate'];
                          final appealStatus =
                              (data['appealStatus'] ?? 'none').toString();
                          final appealMessage =
                              (data['appealMessage'] ?? '').toString();
                          final lastActivationNote =
                              (data['lastActivationNote'] ?? '').toString();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0C2340), Color(0xFF071325)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        formattedRole == 'Service Provider'
                                            ? Icons.handyman_outlined
                                            : Icons.person_outline,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            formattedRole,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.45),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        status,
                                        style: GoogleFonts.poppins(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (status == 'Suspended' || status == 'Restricted') ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: statusColor.withValues(alpha: 0.25)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (suspensionReason.isNotEmpty)
                                          Text(
                                            'Reason: $suspensionReason',
                                            style: GoogleFonts.poppins(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          status == 'Suspended'
                                              ? 'Fully suspended — requires an approved appeal to lift.'
                                              : restrictionEndDate is Timestamp
                                                  ? 'Restricted (still usable) until: ${_formatDate(restrictionEndDate)}'
                                                  : 'Restricted (still usable).',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white70, fontSize: 11),
                                        ),
                                        if (appealStatus == 'pending') ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Appeal submitted: "$appealMessage"',
                                            style: GoogleFonts.poppins(
                                                color: const Color(0xFF38BDF8),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else if (lastActivationNote.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF10B981).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      'Last reactivation note: $lastActivationNote',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 36,
                                        child: OutlinedButton(
                                          onPressed: () => _showUserDetailsDialog(context, data),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFF0284C7)),
                                            foregroundColor: const Color(0xFF38BDF8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text('View', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (status == 'Suspended') {
                                              showActivateAccountDialog(
                                                context: context,
                                                userId: userId,
                                                userName: name,
                                              );
                                            } else {
                                              showSuspendAccountDialog(
                                                context: context,
                                                userId: userId,
                                                userName: name,
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: status == 'Suspended'
                                                ? Colors.green
                                                : AppColors.danger,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            status == 'Suspended' ? 'Activate' : 'Suspend',
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 36,
                                        child: OutlinedButton(
                                          onPressed: () => showAppealHistoryDialog(
                                            context: context,
                                            userId: userId,
                                            userName: name,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.2)),
                                            foregroundColor: Colors.white70,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text('History', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        height: 36,
                                        child: status == 'Suspended'
                                            ? const SizedBox.shrink()
                                            : ElevatedButton(
                                                onPressed: () {
                                                  if (status == 'Restricted') {
                                                    showActivateAccountDialog(
                                                      context: context,
                                                      userId: userId,
                                                      userName: name,
                                                    );
                                                  } else {
                                                    showRestrictAccountDialog(
                                                      context: context,
                                                      userId: userId,
                                                      userName: name,
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      status == 'Restricted'
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                  foregroundColor:
                                                      status == 'Restricted'
                                                          ? Colors.white
                                                          : Colors.orangeAccent,
                                                  elevation: 0,
                                                  side: status == 'Restricted'
                                                      ? BorderSide.none
                                                      : const BorderSide(
                                                          color: Colors.orangeAccent),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                child: Text(
                                                  status == 'Restricted'
                                                      ? 'Unrestrict'
                                                      : 'Restrict',
                                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 34,
                                  child: TextButton.icon(
                                    onPressed: () => _confirmDeleteAccount(
                                      context,
                                      userId,
                                      name,
                                      role,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent.withValues(alpha: 0.8),
                                    ),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    label: Text('Delete Account',
                                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}