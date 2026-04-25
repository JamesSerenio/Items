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

  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color plutoGold = Color(0xFFE5C76B);

  static const Color textPrimary = Color(0xFFF4F8FF);
  static const Color textSecondary = Color(0xFFA7B4D3);
  static const Color textMuted = Color(0xFF7182A8);

  static final BoxDecoration pageBackground = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[backgroundTop, backgroundColor, backgroundBottom],
    ),
  );

  static final BoxDecoration sidebarDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[sidebarColor, sidebarColor2],
    ),
    border: Border.all(color: borderColor, width: 1.1),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 30,
        offset: Offset(0, 18),
      ),
      BoxShadow(color: Color(0x1424D6F2), blurRadius: 20),
    ],
  );

  static final BoxDecoration brandBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.12), plutoGold.withOpacity(0.09)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.20)),
    boxShadow: [
      BoxShadow(
        color: plutoGold.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static final BoxDecoration brandCollapsedDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.22), plutoGold.withOpacity(0.18)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.35)),
  );

  static const TextStyle brandTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.1,
    height: 1,
  );

  static const TextStyle brandMegaTextStyle = TextStyle(
    color: megaGreen,
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
    letterSpacing: 0.5,
  );

  static final BoxDecoration activeMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: LinearGradient(
      colors: [megaGreen.withOpacity(0.20), plutoGold.withOpacity(0.13)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.28)),
    boxShadow: [
      BoxShadow(
        color: megaGreen.withOpacity(0.12),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static final BoxDecoration inactiveMenuDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: Colors.transparent,
    border: Border.all(color: Colors.transparent, width: 1),
  );

  static const TextStyle menuTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle menuInactiveTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static final ButtonStyle logoutButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: const Color(0xFF07111F),
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
