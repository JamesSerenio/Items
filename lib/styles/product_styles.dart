import 'package:flutter/material.dart';

class ProductStyles {
  static const Color primaryColor = Color(0xFF27E0C3);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color dangerColor = Color(0xFFFF6B6B);

  static BoxDecoration get pageBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF020617), Color(0xFF07111F), Color(0xFF020617)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static BoxDecoration get panelDecoration {
    return BoxDecoration(
      color: const Color(0xFF07111F).withOpacity(0.82),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.32),
          blurRadius: 35,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }

  static BoxDecoration get mobilePanelDecoration {
    return BoxDecoration(
      color: const Color(0xFF07111F).withOpacity(0.90),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }

  static const TextStyle pageTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration get statCardDecoration {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    );
  }

  static BoxDecoration get statIconDecoration {
    return BoxDecoration(
      color: primaryColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primaryColor.withOpacity(0.22)),
    );
  }

  static const TextStyle statLabelStyle = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle statValueStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static InputDecoration get searchDecoration {
    return InputDecoration(
      hintText: 'Search supplier, material, unit, or location...',
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.72)),
      prefixIcon: const Icon(Icons.search_rounded, color: textSecondary),
      filled: true,
      fillColor: Colors.white.withOpacity(0.055),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.75)),
      ),
    );
  }

  static ButtonStyle get refreshButtonStyle {
    return IconButton.styleFrom(
      backgroundColor: primaryColor.withOpacity(0.12),
      foregroundColor: primaryColor,
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static Color get tableHeaderColor => Colors.white.withOpacity(0.09);

  static Color get tableRowColor => Colors.white.withOpacity(0.035);

  static BoxDecoration get mobileCardDecoration {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    );
  }

  static const TextStyle mobileTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle mobileSubStyle = TextStyle(
    color: textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle mobileTotalStyle = TextStyle(
    color: primaryColor,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    height: 1.6,
  );

  static const TextStyle emptyStyle = TextStyle(
    color: textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
}
