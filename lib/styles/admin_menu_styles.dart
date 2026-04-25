import 'package:flutter/material.dart';

class AdminMenuStyles {
  static const Color backgroundTop = Color(0xFF03110B);
  static const Color backgroundMid = Color(0xFF07180F);
  static const Color backgroundBottom = Color(0xFF020604);

  static const Color sidebarColor = Color(0xFF07120D);
  static const Color sidebarColor2 = Color(0xFF141006);

  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color megaGreenSoft = Color(0xFF42D99D);
  static const Color plutoGold = Color(0xFFE5C76B);
  static const Color plutoGoldDeep = Color(0xFFB88735);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);
  static const Color textMuted = Color(0xFF8B8061);

  static const Color borderColor = plutoGoldDeep;
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
      colors: [sidebarColor, sidebarColor2],
    ),
    border: Border.all(color: plutoGoldDeep.withOpacity(0.65), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.40),
        blurRadius: 30,
        offset: const Offset(0, 18),
      ),
      BoxShadow(color: megaGreen.withOpacity(0.12), blurRadius: 22),
      BoxShadow(color: plutoGold.withOpacity(0.12), blurRadius: 22),
    ],
  );

  static final BoxDecoration brandBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.16), plutoGold.withOpacity(0.15)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.38)),
    boxShadow: [
      BoxShadow(color: plutoGold.withOpacity(0.12), blurRadius: 16),
      BoxShadow(color: megaGreen.withOpacity(0.10), blurRadius: 16),
    ],
  );

  static final BoxDecoration brandCollapsedDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.32), plutoGold.withOpacity(0.25)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.55)),
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
      colors: [megaGreen.withOpacity(0.30), plutoGold.withOpacity(0.20)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.45), width: 1.1),
    boxShadow: [
      BoxShadow(
        color: megaGreen.withOpacity(0.16),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      BoxShadow(color: plutoGold.withOpacity(0.13), blurRadius: 16),
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
