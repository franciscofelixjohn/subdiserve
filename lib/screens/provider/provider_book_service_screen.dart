import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/provider_bottom_nav_bar.dart';
import 'provider_list_screen.dart';

class ProviderBookServiceScreen extends StatefulWidget {
  const ProviderBookServiceScreen({super.key});

  @override
  State<ProviderBookServiceScreen> createState() =>
      _ProviderBookServiceScreenState();
}

class _ProviderBookServiceScreenState
    extends State<ProviderBookServiceScreen> {
  String searchQuery = '';
  String selectedFilter = 'All';

  Map<String, dynamic> _getCategoryMeta(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('repair') || lower.contains('computer') || lower.contains('appliance')) {
      return {"icon": Icons.build_rounded, "tag": "Repair", "color": const Color(0xFFD97706)};
    } else if (lower.contains('plumbing') || lower.contains('network')) {
      return {"icon": Icons.plumbing_rounded, "tag": "Maintenance", "color": const Color(0xFF0EA5E9)};
    } else if (lower.contains('electrical')) {
      return {"icon": Icons.electric_bolt_rounded, "tag": "Maintenance", "color": const Color(0xFF38BDF8)};
    } else if (lower.contains('aircon')) {
      return {"icon": Icons.ac_unit_rounded, "tag": "Maintenance", "color": const Color(0xFF0284C7)};
    } else if (lower.contains('cleaning') || lower.contains('upholstery') || lower.contains('house cleaning')) {
      return {"icon": Icons.cleaning_services_rounded, "tag": "Cleaning", "color": const Color(0xFF10B981)};
    } else if (lower.contains('painting')) {
      return {"icon": Icons.format_paint_rounded, "tag": "Repair", "color": const Color(0xFFEC4899)};
    } else if (lower.contains('carpentry') || lower.contains('carpenter')) {
      return {"icon": Icons.handyman_rounded, "tag": "Repair", "color": const Color(0xFF8B5CF6)};
    }
    return {"icon": Icons.handyman_rounded, "tag": "Maintenance", "color": const Color(0xFF0EA5E9)};
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Maintenance', 'Repair', 'Cleaning'];

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 1),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ELITE TOP HEADER CARD ---
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MARKETPLACE',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Book a Provider',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Explore expert home service professionals',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        if (Navigator.canPop(context))
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 18),

                  // --- SEARCH BAR ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.8), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => searchQuery = val),
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search service, category, provider...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- FILTER CHIPS ---
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filters.length,
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  selectedFilter = filter;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0284C7)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // --- CATEGORIES HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Categories',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('providers')
                            .where('verificationStatus', isEqualTo: 'approved')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '$count available',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF38BDF8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- CATEGORIES LIST (Consistent Home Style) ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('providers')
                          .where('verificationStatus', isEqualTo: 'approved')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs =
                            snapshot.hasData ? snapshot.data!.docs : [];
                        final Map<String, Map<String, dynamic>>
                            dynamicCategories = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final serviceTitle =
                              data['service'] ?? data['serviceCategory'];
                          if (serviceTitle != null &&
                              serviceTitle.toString().trim().isNotEmpty) {
                            final meta = _getCategoryMeta(serviceTitle);
                            dynamicCategories[serviceTitle] = {
                              "title": serviceTitle,
                              "desc": data['resumeBio'] ??
                                  'Verified professional',
                              "tag": meta['tag'],
                            };
                          }
                        }

                        final categoriesList =
                            dynamicCategories.values.toList();

                        final filteredCategories =
                            categoriesList.where((cat) {
                          final title = cat['title'].toString().toLowerCase();
                          final desc = cat['desc'].toString().toLowerCase();
                          final tag = cat['tag'].toString();
                          final query = searchQuery.toLowerCase();

                          final matchesQuery =
                              title.contains(query) || desc.contains(query);
                          final matchesFilter = selectedFilter == 'All' ||
                              tag == selectedFilter;

                          return matchesQuery && matchesFilter;
                        }).toList();

                        if (filteredCategories.isEmpty) {
                          return Center(
                            child: Text(
                              'No categories found.',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 13.5,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredCategories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            final meta = _getCategoryMeta(cat['title']);
                            final accentColor = meta['color'] as Color;

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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProviderListScreen(
                                          categoryTitle:
                                              cat['title'] as String,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(alpha: 0.2),
                                            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            meta['icon'],
                                            color: accentColor,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: accentColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  meta['tag'],
                                                  style: GoogleFonts.poppins(
                                                    color: accentColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                cat['title'],
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                cat['desc'],
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Color(0xFF38BDF8),
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}