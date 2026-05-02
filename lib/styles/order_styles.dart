import 'package:flutter/material.dart';

class OrderStyles {
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
  static const Color successColor = Color(0xFF42D99D);

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF03110B), Color(0xFF07180F), Color(0xFF020604)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

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

  static final BoxDecoration tableOuterDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
  );

  static Color get tableHeaderColor => const Color(0xFF0F2A1F);
  static Color get tableRowColor => const Color(0xFF07140F);

  static final BoxDecoration cartPanelDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.28),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static final BoxDecoration cartItemDecoration = BoxDecoration(
    color: inputFill,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: plutoGold.withOpacity(0.35)),
  );

  static final BoxDecoration orderItemDecoration = BoxDecoration(
    color: const Color(0xFF081711),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: megaGreenSoft.withOpacity(0.32)),
  );

  static final BoxDecoration totalBoxDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [plutoGold.withOpacity(0.20), megaGreen.withOpacity(0.13)],
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: plutoGold.withOpacity(0.55)),
  );

  static final BoxDecoration unitPillDecoration = BoxDecoration(
    color: plutoGold.withOpacity(0.15),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: plutoGold.withOpacity(0.6)),
  );

  static final BoxDecoration stockBadgeDecoration = BoxDecoration(
    color: successColor.withOpacity(0.14),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: successColor.withOpacity(0.55)),
  );

  static final BoxDecoration outStockDecoration = BoxDecoration(
    color: dangerColor.withOpacity(0.13),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: dangerColor.withOpacity(0.55)),
  );

  static final BoxDecoration qtyButtonDecoration = BoxDecoration(
    color: plutoGold.withOpacity(0.11),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: plutoGold.withOpacity(0.45)),
  );

  static final BoxDecoration topIconDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: plutoGold.withOpacity(0.55)),
  );

  static final BoxDecoration topIconActiveDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [plutoGold.withOpacity(0.28), megaGreen.withOpacity(0.18)],
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: plutoGold),
    boxShadow: [BoxShadow(color: plutoGold.withOpacity(0.22), blurRadius: 18)],
  );

  static final BoxDecoration badgeDecoration = BoxDecoration(
    color: plutoGold,
    borderRadius: BorderRadius.circular(99),
    border: Border.all(color: Colors.black.withOpacity(0.25)),
  );

  static final BoxDecoration flyIconDecoration = BoxDecoration(
    color: plutoGold,
    borderRadius: BorderRadius.circular(99),
    boxShadow: [BoxShadow(color: plutoGold.withOpacity(0.55), blurRadius: 18)],
  );

  static final BoxDecoration popupDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: plutoGold.withOpacity(0.7)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.55),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
    ],
  );

  static final BoxDecoration purchasePaperDecoration = BoxDecoration(
    color: const Color(0xFFFAFAF7),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black54),
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

  static const TextStyle unitPillTextStyle = TextStyle(
    color: plutoGold,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle stockBadgeTextStyle = TextStyle(
    color: successColor,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle outStockTextStyle = TextStyle(
    color: dangerColor,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle cartTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle cartItemNameStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle cartItemMetaStyle = TextStyle(
    color: textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle qtyTextStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle totalLabelStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle totalValueStyle = TextStyle(
    color: plutoGold,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle orderTotalStyle = TextStyle(
    color: plutoGold,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle badgeTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 11,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle popupTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle purchaseTitleStyle = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  );

  static const TextStyle purchaseSubStyle = TextStyle(
    color: Colors.black87,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

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

  static InputDecoration get descriptionInputDecoration {
    return InputDecoration(
      hintText: 'Enter procuring entity...',
      hintStyle: const TextStyle(color: textSecondary),
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

  static ButtonStyle get refreshButtonStyle {
    return IconButton.styleFrom(
      backgroundColor: plutoGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  static ButtonStyle get addCartButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: plutoGold,
      foregroundColor: Colors.black,
      disabledBackgroundColor: Colors.grey.withOpacity(0.25),
      disabledForegroundColor: Colors.white38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
    );
  }

  static ButtonStyle get checkoutButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: plutoGold,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    );
  }

  static ButtonStyle get cancelButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: BorderSide(color: plutoGold.withOpacity(0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
