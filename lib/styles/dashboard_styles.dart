import 'package:flutter/material.dart';

class DashboardStyles {
  static const Color primaryColor = Color(0xFF2ED0FF);
  static const Color secondaryColor = Color(0xFF6C63FF);

  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9FAAC7);

  static const Color borderColor = Color(0xFF1D3D7A);
  static const Color cardColor = Color(0xFF0D1B4D);
  static const Color panelCardColor = Color(0xFF0A1745);

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF020B2D), Color(0xFF041247), Color(0xFF020B2D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final BoxDecoration panelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(32),
    color: const Color(0x1AFFFFFF),
    border: Border.all(color: borderColor, width: 1.2),
    boxShadow: const [
      BoxShadow(
        color: Color(0x26000000),
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration mobilePanelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: const Color(0x1AFFFFFF),
    border: Border.all(color: borderColor, width: 1.1),
    boxShadow: const [
      BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );

  static const TextStyle pageTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardValueStyle = TextStyle(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  static const TextStyle panelTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
}
