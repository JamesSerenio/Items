import 'package:flutter/material.dart';

class DocumentsStyles {
  static const Color megaGreen = Color(0xFF1FAF7A);
  static const Color megaGreenSoft = Color(0xFF42D99D);
  static const Color plutoGold = Color(0xFFE5C76B);
  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);
  static const Color inputFill = Color(0xFF07140F);
  static const Color panelCardColor = Color(0xFF0E1E16);
  static const Color dangerColor = Color(0xFFFF6B6B);

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

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: plutoGold.withOpacity(0.45)),
  );

  static final BoxDecoration selectedCardDecoration = BoxDecoration(
    color: megaGreen.withOpacity(0.16),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: megaGreenSoft, width: 1.5),
  );

  static const TextStyle title = TextStyle(
    color: textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle subtitle = TextStyle(
    color: textSecondary,
    fontSize: 14,
  );

  static const TextStyle folderName = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle small = TextStyle(color: textSecondary, fontSize: 12);

  static InputDecoration searchDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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

  static ButtonStyle goldButton = ElevatedButton.styleFrom(
    backgroundColor: plutoGold,
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.w900),
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: dangerColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.w900),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    side: BorderSide(color: plutoGold.withOpacity(0.7)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
