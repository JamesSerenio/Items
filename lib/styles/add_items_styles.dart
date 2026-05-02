import 'package:flutter/material.dart';

class AddItemsStyles {
  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color plutoGold = Color(0xFFE5C76B);

  static const Color primaryColor = plutoGold;
  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);
  static const Color borderColor = plutoGold;
  static const Color inputFill = Color(0xFF07120D);
  static const Color panelCardColor = Color(0xFF0F1B14);

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
    border: Border.all(color: plutoGold.withOpacity(0.85), width: 1.25),
  );

  static final BoxDecoration mobilePanelDecoration = panelDecoration;

  static final BoxDecoration formCardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: panelCardColor.withOpacity(0.90),
    border: Border.all(color: plutoGold.withOpacity(0.75), width: 1.1),
  );

  static final BoxDecoration totalDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    color: Colors.white.withOpacity(0.06),
    border: Border.all(color: plutoGold.withOpacity(0.35)),
  );

  static const TextStyle pageTitleStyle = TextStyle(
    color: textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );

  static const TextStyle pageTitleMobileStyle = TextStyle(
    color: textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );

  static const TextStyle pageSubtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelStyle = TextStyle(
    color: textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  static ButtonStyle get saveButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: plutoGold,
    foregroundColor: const Color(0xFF07100B),
    elevation: 0,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool alignLabelTop = false,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: plutoGold, size: 18),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 38),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: plutoGold.withOpacity(0.55), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: plutoGold, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: plutoGold.withOpacity(0.55), width: 1),
      ),
    );
  }
}
