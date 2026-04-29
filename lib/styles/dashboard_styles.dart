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
    borderRadius: BorderRadius.circular(18),
    gradient: const LinearGradient(
      colors: [Color(0xFF0B1B13), Color(0xFF10150B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: plutoGold.withOpacity(0.78), width: 1),
  );

  static final BoxDecoration mobilePanelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    gradient: const LinearGradient(
      colors: [Color(0xFF06130D), Color(0xFF0B140C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: plutoGold.withOpacity(0.72), width: .9),
  );

  static const Color cardColor = Color(0xFF0A1A12);
  static const Color panelCardColor = Color(0xFF0B1A12);
  static const Color borderColor = plutoGold;

  static const TextStyle pageTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    fontSize: 10.5,
    color: textSecondary,
    height: 1.25,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 10.5,
    color: textSecondary,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle cardValueStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle panelTitleStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w900,
    color: textPrimary,
  );

  static const TextStyle smallGold = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w900,
    color: plutoGold,
  );

  static const Color primaryColor = plutoGold;
  static const Color secondaryColor = megaGreen;
}
