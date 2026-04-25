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
  static const Color accentPink = Color(0xFF42D99D);

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
    borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [cardColor, cardColor2],
    ),
    border: Border.all(color: primaryColor.withOpacity(0.85), width: 1.25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.42),
        blurRadius: 34,
        offset: const Offset(0, 18),
      ),
      BoxShadow(color: primaryColor.withOpacity(0.14), blurRadius: 28),
    ],
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 14,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF07100B),
    letterSpacing: 0.2,
  );

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(prefixIcon, color: primaryColor, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: primaryColor.withOpacity(0.55),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  static ButtonStyle loginButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: const Color(0xFF07100B),
    elevation: 0,
    minimumSize: const Size(double.infinity, 58),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}
