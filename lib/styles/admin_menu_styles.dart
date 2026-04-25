import 'package:flutter/material.dart';

class AdminMenuStyles {
  static const Color backgroundTop = Color(0xFF03110B);
  static const Color backgroundMid = Color(0xFF07180F);
  static const Color backgroundBottom = Color(0xFF020604);

  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color megaGreenSoft = Color(0xFF42D99D);
  static const Color plutoGold = Color(0xFFE5C76B);
  static const Color plutoGoldDeep = Color(0xFFB88735);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);

  static const Color borderColor = plutoGold;
  static const Color primaryColor = plutoGold;

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundTop, backgroundMid, backgroundBottom],
    ),
  );

  static final BoxDecoration sidebarDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.85), width: 1.25),
    boxShadow: [
      BoxShadow(
        color: plutoGold.withOpacity(0.12),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.40),
        blurRadius: 25,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static final BoxDecoration brandBoxDecoration = const BoxDecoration(
    color: Colors.transparent,
  );

  static final BoxDecoration brandCollapsedDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.35), plutoGold.withOpacity(0.25)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.75)),
  );

  static const TextStyle brandTextStyle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
    height: 1,
  );

  static const TextStyle brandMegaTextStyle = TextStyle(
    color: megaGreenSoft,
    shadows: [Shadow(color: Color(0x661FAF7A), blurRadius: 8)],
  );

  static const TextStyle brandPlutoTextStyle = TextStyle(
    color: plutoGold,
    shadows: [Shadow(color: Color(0x66E5C76B), blurRadius: 8)],
  );

  static const TextStyle brandCollapsedTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: plutoGold,
  );

  static final BoxDecoration activeMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.28), plutoGold.withOpacity(0.20)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.75), width: 1.15),
    boxShadow: [
      BoxShadow(
        color: plutoGold.withOpacity(0.16),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static final BoxDecoration inactiveMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: Colors.transparent,
    border: Border.all(color: Colors.transparent),
  );

  static const TextStyle menuTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const TextStyle menuInactiveTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static final ButtonStyle logoutButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: plutoGold,
    foregroundColor: const Color(0xFF07100B),
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
