import 'package:flutter/material.dart';

class ProductStyles {
  // ===== COLORS =====
  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color megaGreenSoft = Color(0xFF42D99D);

  static const Color plutoGold = Color(0xFFE5C76B);
  static const Color plutoGoldDeep = Color(0xFFB88735);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);

  static const Color inputFill = Color(0xFF07140F);
  static const Color panelCardColor = Color(0xFF0E1E16);

  static const Color borderColor = plutoGold;
  static const Color primaryColor = plutoGold;

  static const Color dangerColor = Color(0xFFFF6B6B);

  // ===== BACKGROUND =====
  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF03110B), Color(0xFF07180F), Color(0xFF020604)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ===== PANEL =====
  static final BoxDecoration panelDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(32),
    gradient: const LinearGradient(
      colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
    ),
    border: Border.all(color: plutoGold.withOpacity(0.7), width: 1.3),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.45),
        blurRadius: 25,
        offset: const Offset(0, 12),
      ),
      BoxShadow(color: plutoGold.withOpacity(0.08), blurRadius: 20),
    ],
  );

  static final BoxDecoration mobilePanelDecoration = panelDecoration;

  // ===== STAT CARDS =====
  static final BoxDecoration statCardDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
  );

  static final BoxDecoration statIconDecoration = BoxDecoration(
    color: inputFill,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: plutoGold.withOpacity(0.7)),
  );

  // ===== TABLE =====
  static final BoxDecoration tableOuterDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
  );

  static Color get tableHeaderColor => const Color(0xFF0F2A1F);
  static Color get tableRowColor => const Color(0xFF07140F);

  // ===== DIALOG =====
  static final BoxDecoration editDialogDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: plutoGold.withOpacity(0.7)),
  );

  // ===== UNIT BADGE =====
  static final BoxDecoration unitPillDecoration = BoxDecoration(
    color: plutoGold.withOpacity(0.15),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
  );

  static const TextStyle unitPillTextStyle = TextStyle(
    color: plutoGold,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  // ===== TEXT =====
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
  );

  static const TextStyle statLabelStyle = TextStyle(
    color: textSecondary,
    fontSize: 13,
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
  );

  static const TextStyle tableHighlightTextStyle = TextStyle(
    color: plutoGold,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle emptyStyle = TextStyle(
    color: textSecondary,
    fontSize: 15,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  // ===== SEARCH =====
  static InputDecoration get searchDecoration {
    return InputDecoration(
      hintStyle: const TextStyle(color: textSecondary),
      prefixIcon: const Icon(Icons.search_rounded, color: plutoGold),
      filled: true,
      fillColor: inputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: plutoGold.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: plutoGold),
      ),
    );
  }

  // ===== BUTTONS =====
  static ButtonStyle get refreshButtonStyle {
    return IconButton.styleFrom(
      backgroundColor: plutoGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  static ButtonStyle get cancelButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: BorderSide(color: plutoGold.withOpacity(0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ButtonStyle get saveEditButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: plutoGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
