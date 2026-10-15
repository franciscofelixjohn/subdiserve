import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/provider/provider_book_service_screen.dart';
import '../screens/provider/provider_dashboard_screen.dart';
import '../screens/provider/provider_profile_screen.dart';
import '../screens/provider/provider_schedule_screen.dart';

class ProviderBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ProviderBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  // Handle navigation switching between provider screens
  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetScreen;

    switch (index) {
      case 0:
        targetScreen = const ProviderDashboardScreen();
        break;
      case 1:
        targetScreen = const ProviderBookServiceScreen();
        break;
      case 2:
        targetScreen = const ProviderScheduleScreen();
        break;
      case 3:
        targetScreen = const ChatListScreen();
        break;
      case 4:
        targetScreen = const ProviderProfileScreen();
        break;
      default:
        targetScreen = const ProviderDashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Home',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 1,
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
              label: 'Book',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 2,
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today_rounded,
              label: 'Schedule',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 3,
              icon: Icons.message_outlined,
              activeIcon: Icons.message_rounded,
              label: 'Messages',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build individual elite navigation items
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 8 : 4,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0284C7).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  width: 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}