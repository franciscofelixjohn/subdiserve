import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/admin/admin_provider_verification_screen.dart';
import '../../screens/admin/admin_user_management_screen.dart';
import '../../screens/admin/admin_booking_monitoring_screen.dart';
import '../../screens/admin/admin_manage_categories_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(context),
      const AdminUserManagementScreen(),
      const AdminBookingMonitoringScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF061021),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_grid_2x2_fill),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_3_fill),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar_badge_plus),
              label: 'Bookings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP HEADER & CONTROL CENTER BANNER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C2340), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMINISTRATION SUITE',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control Center',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _logout(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        CupertinoIcons.square_arrow_right,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- REAL-TIME STATS OVERVIEW ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('providers').snapshots(),
                  builder: (context, providerSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                      builder: (context, bookingSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('providers')
                              .where('verificationStatus', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, pendingSnapshot) {
                            final userCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                            final providerCount = providerSnapshot.hasData ? providerSnapshot.data!.docs.length : 0;
                            final bookingCount = bookingSnapshot.hasData ? bookingSnapshot.data!.docs.length : 0;
                            final pendingCount = pendingSnapshot.hasData ? pendingSnapshot.data!.docs.length : 0;

                            return Row(
                              children: [
                                Expanded(child: _buildStatCard('$userCount', 'Users', CupertinoIcons.person_2_fill)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildStatCard('$providerCount', 'Providers', CupertinoIcons.wrench_fill)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildStatCard('$bookingCount', 'Bookings', CupertinoIcons.calendar)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildStatCard('$pendingCount', 'Pending', CupertinoIcons.exclamationmark_triangle_fill, isAlert: pendingCount > 0)),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // --- MANAGEMENT TOOLS SECTION ---
            Text(
              'Management Tools',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Pinagandang malalaking cards na sinulit ang espasyo at may gradient colors
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPremiumGradientCard(
                            context,
                            title: 'Verify Providers',
                            subtitle: 'Review CVs & status',
                            icon: CupertinoIcons.checkmark_shield_fill,
                            gradientColors: const [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF0F172A)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminProviderVerificationScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPremiumGradientCard(
                            context,
                            title: 'User Management',
                            subtitle: 'Accounts & roles',
                            icon: CupertinoIcons.person_3_fill,
                            gradientColors: const [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF0F172A)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPremiumGradientCard(
                            context,
                            title: 'Bookings Center',
                            subtitle: 'Monitor schedules',
                            icon: CupertinoIcons.ticket_fill,
                            gradientColors: const [Color(0xFF047857), Color(0xFF059669), Color(0xFF0F172A)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminBookingMonitoringScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPremiumGradientCard(
                            context,
                            title: 'Service Categories',
                            subtitle: 'Add & edit services',
                            icon: CupertinoIcons.square_grid_2x2_fill,
                            gradientColors: const [Color(0xFFB45309), Color(0xFFD97706), Color(0xFF0F172A)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminManageCategoriesScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: _buildWidePremiumGradientCard(
                      context,
                      title: 'System Reports',
                      subtitle: 'Analytics & logs',
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      gradientColors: const [Color(0xFFB91C1C), Color(0xFFDC2626), Color(0xFF0F172A)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF0C2340),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isAlert ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)),
          const SizedBox(height: 3),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGradientCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidePremiumGradientCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}