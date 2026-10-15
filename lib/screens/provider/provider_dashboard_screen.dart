import 'dart:convert';
import 'provider_job_history_screen.dart';
import 'provider_booking_requests_page.dart';
import 'provider_portfolio_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/booking_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/provider_bottom_nav_bar.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  String _providerName = 'User';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  // Fetch provider profile details from Firestore
  Future<void> _fetchProviderData() async {
    try {
      final String providerId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _providerName = data['name'] ??
              data['fullName'] ??
              data['username'] ??
              'User';
          _profileImageUrl = data['profileImageUrl'] ?? data['photoUrl'];
        });
      }
    } catch (e) {
      // Keep fallback
    }
  }

  // Dialog to create a new work portfolio post
  void _showCreatePostDialog(BuildContext context) {
    final captionController = TextEditingController();
    final priceController = TextEditingController();
    List<Uint8List> pickedImagesBytes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          title: Text(
            'Create New Work Post',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final images = await picker.pickMultiImage(imageQuality: 70);
                            if (images.isNotEmpty) {
                              List<Uint8List> newBytes = [];
                              for (var img in images) {
                                newBytes.add(await img.readAsBytes());
                              }
                              setDialogState(() {
                                pickedImagesBytes.addAll(newBytes);
                              });
                            }
                          },
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF38BDF8), size: 28),
                                const SizedBox(height: 6),
                                Text('Add Photo', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        ...pickedImagesBytes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final bytes = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(left: 12),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(bytes, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        pickedImagesBytes.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: captionController,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description / Caption / Text Post',
                      labelStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.5),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priceController,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: 'Price or Budget Range (e.g., ₱500 - ₱1,000)',
                      labelStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 12.5),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontWeight: FontWeight.w500)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (captionController.text.trim().isEmpty && pickedImagesBytes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add a photo or caption.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final userDoc = await FirebaseFirestore.instance.collection('providers').doc(user.uid).get();
                  final providerName = userDoc.data()?['name'] ?? user.displayName ?? 'Service Provider';
                  final category = userDoc.data()?['service'] ?? userDoc.data()?['serviceCategory'] ?? 'General Service';

                  List<String> imageList = [];
                  for (var bytes in pickedImagesBytes) {
                    imageList.add('data:image/jpeg;base64,${base64Encode(bytes)}');
                  }

                  await FirebaseFirestore.instance.collection('provider_posts').add({
                    'providerId': user.uid,
                    'providerName': providerName,
                    'category': category,
                    'imageUrl': imageList.isNotEmpty ? imageList.first : '',
                    'imageList': imageList,
                    'caption': captionController.text.trim(),
                    'priceRange': priceController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'likes': [],
                  });

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post published successfully!'), backgroundColor: Color(0xFF10B981)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post failed: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl, String fallbackName) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.startsWith('demo')) {
      return _buildAvatarFallback(fallbackName);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackName),
        );
      } catch (_) {
        return _buildAvatarFallback(fallbackName);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String providerId = FirebaseAuth.instance.currentUser!.uid;
    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 0),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF030712),
                  Color(0xFF0B132B),
                  Color(0xFF030712),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // --- CONSISTENT HOME / DASHBOARD TOP HEADER CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _buildImageWidget(_profileImageUrl, _providerName),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _providerName,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF38BDF8),
                                          size: 11,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Provider',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF38BDF8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const NotificationBellButton(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.work_outline_rounded, color: const Color(0xFF38BDF8).withValues(alpha: 0.8), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Manage your active jobs and earnings',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- TODAY OVERVIEW STATS ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today Overview',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<Map<String, dynamic>>(
                        stream: bookingService.getProviderDashboardStats(providerId),
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? <String, dynamic>{};
                          final acceptedJobs = stats['acceptedJobs'] ?? 0;
                          final weeklyEarnings =
                              (stats['weeklyEarnings'] ?? 0).toDouble();

                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0F172A),
                                        Color(0xFF1E293B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acceptedJobs.toString(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF38BDF8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accepted Jobs',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0F172A),
                                        Color(0xFF1E293B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₱${weeklyEarnings.toStringAsFixed(2)}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF38BDF8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Weekly Earnings',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  // --- QUICK ACTIONS GRID ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.25,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('providerId', isEqualTo: providerId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int pendingCount = 0;
                              if (snapshot.hasData) {
                                pendingCount = snapshot.data!.docs.where((doc) {
                                  final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                                  return status.toString().toLowerCase() == 'pending' || 
                                         status.toString().toLowerCase() == 'confirmed';
                                }).length;
                              }

                              return _buildActionCard(
                                context,
                                title: 'Job Requests',
                                icon: Icons.assignment_rounded,
                                badgeCount: pendingCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProviderBookingRequestsPage(providerId: providerId),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          _buildActionCard(
                            context,
                            title: 'Job History',
                            icon: Icons.history_rounded,
                            badgeCount: 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProviderJobHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionCard(
                            context,
                            title: 'Create Post',
                            icon: Icons.post_add_rounded,
                            badgeCount: 0,
                            onTap: () => _showCreatePostDialog(context),
                          ),
                          _buildActionCard(
                            context,
                            title: 'My Portfolio',
                            icon: Icons.photo_library_rounded,
                            badgeCount: 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProviderPortfolioScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          icon,
                          size: 28,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}