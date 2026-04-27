import 'package:flutter/material.dart';

class LoginStyles {
  static const Color backgroundColor = Color(0xFF07180F);
  static const Color backgroundTop = Color(0xFF03110B);
  static const Color backgroundBottom = Color(0xFF020604);

  static const Color cardColor = Color(0xFF0B1B13);
  static const Color cardColor2 = Color(0xFF13140C);
  static const Color borderColor = Color(0xFFE5C76B);

  static const Color primaryColor = Color(0xFFE5C76B);
  static const Color secondaryColor = Color(0xFF1FAF7A);
  static const Color accentGreen = Color(0xFF42D99D);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);
  static const Color textMuted = Color(0xFF8B8061);

  static const Color inputFill = Color(0xFF07120D);

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundTop, backgroundColor, backgroundBottom],
    ),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(32),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF102318), cardColor, cardColor2],
    ),
    border: Border.all(color: primaryColor.withOpacity(0.75), width: 1.35),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.50),
        blurRadius: 38,
        offset: const Offset(0, 20),
      ),
      BoxShadow(
        color: primaryColor.withOpacity(0.18),
        blurRadius: 34,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: secondaryColor.withOpacity(0.08),
        blurRadius: 46,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration logoGlowDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.34),
        blurRadius: 42,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: secondaryColor.withOpacity(0.16),
        blurRadius: 30,
        spreadRadius: 1,
      ),
    ],
  );

  static const TextStyle brandStyle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: 2.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 14,
    color: textPrimary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF07100B),
    letterSpacing: 0.4,
  );

  static BoxDecoration smallDivider = BoxDecoration(
    borderRadius: BorderRadius.circular(99),
    gradient: LinearGradient(
      colors: [
        primaryColor.withOpacity(0.15),
        primaryColor.withOpacity(0.9),
        secondaryColor.withOpacity(0.85),
        primaryColor.withOpacity(0.15),
      ],
    ),
  );

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(prefixIcon, color: primaryColor, size: 21),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 52),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: BorderSide(
          color: primaryColor.withOpacity(0.48),
          width: 1.15,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: primaryColor, width: 1.65),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.15),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.65),
      ),
    );
  }

  static ButtonStyle loginButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: const Color(0xFF07100B),
    disabledBackgroundColor: primaryColor.withOpacity(0.55),
    disabledForegroundColor: const Color(0xFF07100B).withOpacity(0.65),
    elevation: 0,
    minimumSize: const Size(double.infinity, 58),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
    textStyle: buttonTextStyle,
  );
}
