import 'package:flutter/material.dart';

class ProductStyles {
  static const Color primaryColor = Color(0xFF31C7E3);
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9FAAC7);
  static const Color borderColor = Color(0xFF1D3D7A);
  static const Color inputFill = Color(0xFF061542);
  static const Color panelCardColor = Color(0xFF0A1745);
  static const Color dangerColor = Color(0xFFFF6B6B);

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
  );

  static final BoxDecoration mobilePanelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: const Color(0x1AFFFFFF),
    border: Border.all(color: borderColor, width: 1.1),
  );

  static final BoxDecoration statCardDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: borderColor, width: 1.1),
  );

  static final BoxDecoration statIconDecoration = BoxDecoration(
    color: inputFill,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: primaryColor, width: 1.1),
  );

  static final BoxDecoration tableOuterDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderColor, width: 1.1),
  );

  static final BoxDecoration editDialogDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: borderColor, width: 1.2),
  );

  static final BoxDecoration unitPillDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primaryColor.withOpacity(0.35)),
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle unitPillTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle pageTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle statLabelStyle = TextStyle(
    color: textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle statValueStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle tableHeaderTextStyle = TextStyle(
    color: textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle tableCellTextStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle tableHighlightTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle emptyStyle = TextStyle(
    color: textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static InputDecoration get searchDecoration {
    return InputDecoration(
      hintText: 'Search supplier, material, unit, or location...',
      hintStyle: const TextStyle(color: textSecondary),
      prefixIcon: const Icon(Icons.search_rounded, color: textSecondary),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1.1),
      ),
    );
  }

  static ButtonStyle get refreshButtonStyle {
    return IconButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  static ButtonStyle get mobileRefreshButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
    );
  }

  static ButtonStyle get cancelButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: const BorderSide(color: borderColor),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ButtonStyle get saveEditButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static Color get tableHeaderColor => const Color(0xFF0B1B54);
  static Color get tableRowColor => const Color(0xFF07184D);
}
