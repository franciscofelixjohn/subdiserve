import 'package:material_ui/material_ui.dart';

class AppColors {
  static const Color primary = Color(0xFF0A84FF);
  static const Color secondary = Color(0xFF5AC8FA);

  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient gradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}