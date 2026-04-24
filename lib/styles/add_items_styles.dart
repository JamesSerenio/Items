import 'package:flutter/material.dart';

class AddItemsStyles {
  static const Color primaryColor = Color(0xFF31C7E3);
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9FAAC7);
  static const Color borderColor = Color(0xFF1D3D7A);
  static const Color inputFill = Color(0xFF061542);
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

  static final BoxDecoration formCardDecoration = BoxDecoration(
    color: panelCardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderColor, width: 1.1),
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

  static const TextStyle labelStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static ButtonStyle get saveButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.black,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool alignLabelTop = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: alignLabelTop
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, bottom: 54),
              child: Icon(prefixIcon, color: textSecondary, size: 24),
            )
          : Icon(prefixIcon, color: textSecondary, size: 24),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      filled: true,
      fillColor: inputFill,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: alignLabelTop ? 20 : 18,
      ),
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
}
