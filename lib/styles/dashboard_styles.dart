import 'package:flutter/material.dart';

class DashboardStyles {
  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color megaGreenSoft = Color(0xFF42D99D);

  static const Color plutoGold = Color(0xFFE5C76B);
  static const Color plutoGoldDeep = Color(0xFFB88735);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);

  static const Color danger = Color(0xFFFF6B6B);
  static const Color blue = Color(0xFF7DD3FC);

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF03110B), Color(0xFF07180F), Color(0xFF020604)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final BoxDecoration panelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: plutoGold.withOpacity(0.85), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.42),
        blurRadius: 25,
        offset: const Offset(0, 12),
      ),
      BoxShadow(color: plutoGold.withOpacity(0.08), blurRadius: 28),
    ],
  );

  static final BoxDecoration mobilePanelDecoration = panelDecoration;

  static const Color cardColor = Color(0xFF0E1E16);
  static const Color panelCardColor = Color(0xFF0F1B14);
  static const Color borderColor = plutoGold;

  static const TextStyle pageTitleStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.45,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 13,
    color: textSecondary,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardValueStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle panelTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle smallGold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: plutoGold,
  );

  static const Color primaryColor = plutoGold;
  static const Color secondaryColor = megaGreen;
}
