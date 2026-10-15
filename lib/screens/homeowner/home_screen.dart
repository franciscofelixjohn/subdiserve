import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../widgets/bottom_nav_bar.dart';
import '../../../../widgets/notification_bell_button.dart';
import '../../../../services/category_service.dart';
import '../provider/provider_list_screen.dart';

class HomeownerHomeScreen extends StatefulWidget {
  const HomeownerHomeScreen({super.key});

  @override
  State<HomeownerHomeScreen> createState() => _HomeownerHomeScreenState();
}

class _HomeownerHomeScreenState extends State<HomeownerHomeScreen> {
  String userName = 'User';
  String? profileImageUrl;
  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            userName = data['fullName'] ?? data['name'] ?? data['username'] ?? 'User';
            profileImageUrl = data['selfieUrl'] ?? data['profileImageUrl'] ?? data['validIdUrl'] ?? data['photoUrl'];
          });
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  Map<String, dynamic> _getCategoryMeta(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('plumbing')) {
      return {"icon": Icons.plumbing_rounded, "tag": "Maintenance", "color": const Color(0xFF38BDF8), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('electrical') || lower.contains('electric')) {
      return {"icon": Icons.bolt_rounded, "tag": "Maintenance", "color": const Color(0xFF38BDF8), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('carpentry') || lower.contains('carpenter')) {
      return {"icon": Icons.handyman_rounded, "tag": "Maintenance", "color": const Color(0xFF818CF8), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('painting') || lower.contains('painter')) {
      return {"icon": Icons.format_paint_rounded, "tag": "Maintenance", "color": const Color(0xFFF472B6), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('aircon') || lower.contains('cooling')) {
      return {"icon": Icons.ac_unit_rounded, "tag": "Maintenance", "color": const Color(0xFF22D3EE), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('cleaning') || lower.contains('house cleaning')) {
      return {"icon": Icons.cleaning_services_rounded, "tag": "Cleaning", "color": const Color(0xFF34D399), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('computer') || lower.contains('laptop') || lower.contains('it')) {
      return {"icon": Icons.computer_rounded, "tag": "Repair", "color": const Color(0xFFA78BFA), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('network') || lower.contains('wifi')) {
      return {"icon": Icons.router_rounded, "tag": "Repair", "color": const Color(0xFF60A5FA), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    } else if (lower.contains('appliance')) {
      return {"icon": Icons.kitchen_rounded, "tag": "Repair", "color": const Color(0xFFFBBF24), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
    }
    return {"icon": Icons.home_repair_service_rounded, "tag": "Maintenance", "color": const Color(0xFF38BDF8), "cardGradient": [const Color(0xFF0F172A), const Color(0xFF1E293B)]};
  }

  Widget _buildUserAvatar() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty && !profileImageUrl!.startsWith('demo')) {
      if (profileImageUrl!.startsWith('data:image')) {
        try {
          return Image.memory(
            Uri.parse(profileImageUrl!).data!.contentAsBytes(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildAvatarFallback(),
          );
        } catch (_) {
          return _buildAvatarFallback();
        }
      }
      return Image.network(
        profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildAvatarFallback(),
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Maintenance', 'Repair', 'Cleaning'];

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: Stack(
        children: [
          // Luxury Ambient Lighting Orbs
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ELITE HERO IDENTITY CARD ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(2.5),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF020617),
                                    ),
                                    child: ClipOval(
                                      child: _buildUserAvatar(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 13),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Verified Homeowner',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF38BDF8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Luxury Notification Button Container
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const NotificationBellButton(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Ultra-Modern Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => searchQuery = val),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search expert home services...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- STYLISH FILTER PILLS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filters.length,
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => setState(() => selectedFilter = filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                filter,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- SERVICES FEED LIST ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: CategoryService().streamCategories(),
                    builder: (context, categorySnapshot) {
                      final categoryDocs = categorySnapshot.data?.docs ?? [];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('providers')
                            .where('verificationStatus', isEqualTo: 'approved')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.hasData ? snapshot.data!.docs : [];
                          final Map<String, Map<String, dynamic>> dynamicCategories = {};

                          for (var doc in categoryDocs) {
                            final data = doc.data();
                            final title = (data['title'] ?? '').toString();
                            if (title.trim().isNotEmpty) {
                              dynamicCategories[title] = {
                                'title': title,
                                'desc': (data['description'] ?? '').toString(),
                                'tag': (data['tag'] ?? 'Maintenance').toString(),
                              };
                            }
                          }

                          for (var doc in docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final serviceTitle = data['service'] ?? data['serviceCategory'];
                            if (serviceTitle != null && serviceTitle.toString().trim().isNotEmpty) {
                              final titleStr = serviceTitle.toString();
                              if (!dynamicCategories.containsKey(titleStr)) {
                                final meta = _getCategoryMeta(titleStr);
                                dynamicCategories[titleStr] = {
                                  "title": titleStr,
                                  "desc": data['experience'] ?? 'Verified professional',
                                  "tag": meta['tag'],
                                };
                              }
                            }
                          }

                          final categoriesList = dynamicCategories.values.toList();
                          final filteredCategories = categoriesList.where((cat) {
                            final title = cat['title'].toString().toLowerCase();
                            final desc = cat['desc'].toString().toLowerCase();
                            final tag = cat['tag'].toString();
                            final query = searchQuery.toLowerCase();

                            final matchesQuery = title.contains(query) || desc.contains(query);
                            final matchesFilter = selectedFilter == 'All' || tag == selectedFilter;

                            return matchesQuery && matchesFilter;
                          }).toList();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Available Services',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '${filteredCategories.length} active',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF38BDF8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: filteredCategories.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.explore_off_rounded, color: Colors.white24, size: 60),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No services found.',
                                                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: filteredCategories.length,
                                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                                          itemBuilder: (context, index) {
                                            final cat = filteredCategories[index];
                                            final meta = _getCategoryMeta(cat['title']);
                                            final Color accentColor = meta['color'];
                                            final List<Color> cardGradient = meta['cardGradient'];

                                            return Container(
                                              height: 130,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(28),
                                                gradient: LinearGradient(
                                                  colors: cardGradient,
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                border: Border.all(
                                                  color: accentColor.withValues(alpha: 0.35),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: accentColor.withValues(alpha: 0.15),
                                                    blurRadius: 24,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(28),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ProviderListScreen(
                                                          categoryTitle: cat['title'] as String,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 70,
                                                          height: 70,
                                                          decoration: BoxDecoration(
                                                            color: accentColor.withValues(alpha: 0.18),
                                                            borderRadius: BorderRadius.circular(22),
                                                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Icon(
                                                            meta['icon'],
                                                            color: accentColor,
                                                            size: 34,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 18),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                                                decoration: BoxDecoration(
                                                                  color: accentColor.withValues(alpha: 0.15),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Text(
                                                                  cat['tag'],
                                                                  style: GoogleFonts.poppins(
                                                                    color: accentColor,
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(height: 6),
                                                              Text(
                                                                cat['title'],
                                                                style: GoogleFonts.outfit(
                                                                  color: Colors.white,
                                                                  fontSize: 19,
                                                                  fontWeight: FontWeight.w700,
                                                                  letterSpacing: -0.3,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                cat['desc'],
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors.white.withValues(alpha: 0.6),
                                                                  fontSize: 12.5,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withValues(alpha: 0.08),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.arrow_forward_rounded,
                                                            color: accentColor,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
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