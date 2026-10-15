import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProviderVerificationScreen extends StatefulWidget {
  const AdminProviderVerificationScreen({super.key});

  @override
  State<AdminProviderVerificationScreen> createState() => _AdminProviderVerificationScreenState();
}

class _AdminProviderVerificationScreenState extends State<AdminProviderVerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateVerificationStatus(
      BuildContext context, String providerId, String status, String providerName, {String? declineReason}) async {
    try {
      final updateData = <String, dynamic>{
        'verificationStatus': status,
      };

      if (status == 'approved') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['declineReason'] = FieldValue.delete();
      } else if (status == 'rejected') {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
        if (declineReason != null && declineReason.trim().isNotEmpty) {
          updateData['declineReason'] = declineReason.trim();
        }
      }

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .update(updateData);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully ${status == 'approved' ? 'approved' : 'rejected'} $providerName'),
          backgroundColor: status == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeclineDialog(BuildContext context, String providerId, String providerName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0C2340),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Decline Provider',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting $providerName:',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid credentials or incomplete resume',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _updateVerificationStatus(context, providerId, 'rejected', providerName,
                  declineReason: reasonController.text);
            },
            child: Text('Confirm Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
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
        elevation: 0,
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        title: Text(
          'Provider Verifications',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2340),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
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
            padding: const EdgeInsets.all(16.0),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProviderList('pending'),
                _buildProviderList('approved'),
                _buildProviderList('rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .where('verificationStatus', isEqualTo: statusFilter)
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
              'No $statusFilter providers found.',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          itemCount: docs.length,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final providerId = docs[index].id;
            final name = data['name'] ?? data['fullName'] ?? 'Unknown Provider';
            final service = data['service'] ?? data['serviceType'] ?? 'General Service';
            final bio = data['resumeBio'] ?? 'No bio summary provided';
            final resumeUrl = data['resumeFileUrl'] ?? 'No resume uploaded';
            final declineReason = data['declineReason'];

            Color badgeColor;
            if (statusFilter == 'approved') {
              badgeColor = Colors.green;
            } else if (statusFilter == 'rejected') {
              badgeColor = Colors.redAccent;
            } else {
              badgeColor = Colors.orange;
            }

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
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
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
                              service,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              bio,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusFilter[0].toUpperCase() + statusFilter.substring(1),
                          style: GoogleFonts.poppins(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resume URL: $resumeUrl',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusFilter == 'rejected' && declineReason != null && declineReason.toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Reason: $declineReason',
                        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (statusFilter == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton(
                              onPressed: () => _showDeclineDialog(context, providerId, name),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Decline', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () => _updateVerificationStatus(context, providerId, 'approved', name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Approve', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _updateVerificationStatus(
                          context,
                          providerId,
                          statusFilter == 'approved' ? 'rejected' : 'approved',
                          name,
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: Text(
                          statusFilter == 'approved' ? 'Move to Rejected' : 'Re-approve',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}