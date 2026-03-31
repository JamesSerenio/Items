import 'package:flutter/material.dart';

class LoginStyles {
  static const Color backgroundColor = Color(0xFF090F20);
  static const Color backgroundTop = Color(0xFF0C1430);
  static const Color backgroundBottom = Color(0xFF070B18);

  static const Color cardColor = Color(0xFF151D3A);
  static const Color cardColor2 = Color(0xFF10182F);
  static const Color borderColor = Color(0xFF22345D);

  static const Color primaryColor = Color(0xFF24D6F2);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);

  static const Color textPrimary = Color(0xFFF4F8FF);
  static const Color textSecondary = Color(0xFFA7B4D3);
  static const Color textMuted = Color(0xFF7182A8);

  static const Color inputFill = Color(0xFF0E1730);

  static BoxDecoration pageBackground = const BoxDecoration(
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
    border: Border.all(color: borderColor, width: 1.1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 36,
        offset: Offset(0, 20),
      ),
      BoxShadow(color: Color(0x1824D6F2), blurRadius: 28, offset: Offset(0, 0)),
    ],
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 14,
    color: textPrimary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Color(0xFF07111F),
    letterSpacing: 0.2,
  );

  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: textSecondary, size: 20),
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1.1),
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
    foregroundColor: const Color(0xFF07111F),
    elevation: 0,
    minimumSize: const Size(double.infinity, 58),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}
