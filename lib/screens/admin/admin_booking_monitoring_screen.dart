import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'admin_booking_manage_screen.dart';
import 'admin_booking_progress_screen.dart';

class AdminBookingMonitoringScreen extends StatelessWidget {
  const AdminBookingMonitoringScreen({super.key});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Booking Monitoring',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Bookings',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Monitor all booking transactions in the platform real-time',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No bookings found in the system.',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: docs.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final bookingId = docs[index].id;
                      final service = (data['service'] ?? data['serviceName'] ?? 'General Service').toString();
                      final homeowner = (data['homeownerName'] ?? data['homeowner'] ?? 'Unknown Resident').toString();
                      final provider = (data['providerName'] ?? data['provider'] ?? 'Unassigned').toString();
                      final providerId = (data['providerId'] ?? '').toString();
                      final status = (data['status'] ?? 'Pending').toString();
                      final statusColor = getStatusColor(status);

                      // The booking's originally scheduled date/time.
                      String date = (data['bookingDate'] ?? data['date'] ?? 'N/A').toString();
                      String time = (data['bookingTime'] ?? data['time'] ?? 'N/A').toString();

                      // For completed jobs, show when it was actually
                      // finished instead of just the original schedule.
                      final completedAt = data['completedAt'];
                      if (status.toLowerCase() == 'completed' && completedAt is Timestamp) {
                        final d = completedAt.toDate();
                        final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
                        final ampm = d.hour >= 12 ? 'PM' : 'AM';
                        date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} (completed)';
                        time = '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Homeowner: $homeowner',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'Provider: $provider',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(date, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time_outlined, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(time, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdminBookingProgressScreen(
                                              bookingId: bookingId,
                                              providerId: providerId,
                                              providerName: provider,
                                              homeownerName: homeowner,
                                              service: service,
                                              status: status,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF0EA5E9)),
                                        foregroundColor: const Color(0xFF0EA5E9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text('View Details', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdminBookingManageScreen(
                                              bookingId: bookingId,
                                              providerId: providerId,
                                              providerName: provider,
                                              homeownerName: homeowner,
                                              service: service,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0EA5E9),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text('Manage', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}