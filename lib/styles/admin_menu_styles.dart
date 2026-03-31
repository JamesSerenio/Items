import 'package:flutter/material.dart';

class AdminMenuStyles {
  static const Color backgroundColor = Color(0xFF0A1022);
  static const Color backgroundTop = Color(0xFF0C1430);
  static const Color backgroundBottom = Color(0xFF070B18);

  static const Color sidebarColor = Color(0xFF131B37);
  static const Color sidebarColor2 = Color(0xFF10172F);
  static const Color panelColor = Color(0xFF151D3A);
  static const Color panelColor2 = Color(0xFF10182F);

  static const Color borderColor = Color(0xFF24345F);
  static const Color primaryColor = Color(0xFF24D6F2);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);

  static const Color textPrimary = Color(0xFFF4F8FF);
  static const Color textSecondary = Color(0xFFA7B4D3);
  static const Color textMuted = Color(0xFF7182A8);

  static BoxDecoration pageBackground = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundTop, backgroundColor, backgroundBottom],
    ),
  );

  static BoxDecoration sidebarDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [sidebarColor, sidebarColor2],
    ),
    border: Border.all(color: borderColor, width: 1.1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 30,
        offset: Offset(0, 18),
      ),
      BoxShadow(color: Color(0x1424D6F2), blurRadius: 20, offset: Offset(0, 0)),
    ],
  );

  static BoxDecoration panelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [panelColor, panelColor2],
    ),
    border: Border.all(color: borderColor, width: 1.1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration activeMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: const Color(0x1624D6F2),
    border: Border.all(color: const Color(0x3324D6F2), width: 1),
    boxShadow: const [
      BoxShadow(color: Color(0x1424D6F2), blurRadius: 16, offset: Offset(0, 0)),
    ],
  );

  static BoxDecoration inactiveMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: Colors.transparent,
    border: Border.all(color: Colors.transparent, width: 1),
  );

  static const TextStyle brandStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle menuTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle menuInactiveTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle pageTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle cardValueStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 13,
    color: textMuted,
    fontWeight: FontWeight.w500,
  );

  static ButtonStyle logoutButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: const Color(0xFF07111F),
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
