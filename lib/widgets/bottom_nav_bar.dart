import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/homeowner/active_bookings_screen.dart';
import '../screens/homeowner/home_screen.dart';
import '../screens/homeowner/profile_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetScreen;

    switch (index) {
      case 0:
        targetScreen = const HomeownerHomeScreen();
        break;
      case 1:
        targetScreen = const ActiveBookingsScreen();
        break;
      case 2:
        targetScreen = const ChatListScreen();
        break;
      case 3:
        targetScreen = const ProfileScreen();
        break;
      default:
        targetScreen = const HomeownerHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
              _buildNavItem(context, 1, Icons.calendar_today_rounded, 'Bookings'),
              _buildNavItem(context, 2, Icons.chat_bubble_rounded, 'Messages'),
              _buildNavItem(context, 3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}