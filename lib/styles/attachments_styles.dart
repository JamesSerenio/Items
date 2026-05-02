import 'package:flutter/material.dart';

class AttachmentsStyles {
  static const Color bg = Color(0xFF0E1E16);
  static const Color bgDark = Color(0xFF07140F);
  static const Color card = Color(0xFF081711);

  static const Color gold = Color(0xFFE5C76B);
  static const Color green = Color(0xFF1FAF7A);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color blue = Color(0xFF7DD3FC);

  static const Color textPrimary = Color(0xFFF9F2D7);
  static const Color textSecondary = Color(0xFFC6B98F);

  static double scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= 430) return 0.72;
    if (w <= 900) return 0.82;
    return 1.0;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final s = scale(context);
    return EdgeInsets.all(24 * s);
  }

  static BorderRadius radius(BuildContext context) {
    final s = scale(context);
    return BorderRadius.circular(28 * s);
  }

  static BoxDecoration panelOf(BuildContext context) {
    final s = scale(context);
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28 * s),
      border: Border.all(color: gold.withOpacity(0.65), width: 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 24 * s,
          offset: Offset(0, 12 * s),
        ),
      ],
    );
  }

  static final BoxDecoration panel = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: gold.withOpacity(0.65), width: 1.2),
  );

  static BoxDecoration cardStyleOf(BuildContext context) {
    final s = scale(context);
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(20 * s),
      border: Border.all(color: gold.withOpacity(0.35)),
    );
  }

  static final BoxDecoration cardStyle = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: gold.withOpacity(0.35)),
  );

  static BoxDecoration outlineBtnOf(BuildContext context) {
    final s = scale(context);
    return BoxDecoration(
      color: bgDark,
      borderRadius: BorderRadius.circular(14 * s),
      border: Border.all(color: gold.withOpacity(0.55)),
    );
  }

  static final BoxDecoration outlineBtn = BoxDecoration(
    color: bgDark,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: gold.withOpacity(0.55)),
  );

  static final BoxDecoration tableHeader = BoxDecoration(
    color: const Color(0xFF0F2A1F),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: gold.withOpacity(0.35)),
  );

  static final BoxDecoration statusDone = BoxDecoration(
    color: green.withOpacity(0.13),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: green.withOpacity(0.55)),
  );

  static final BoxDecoration statusPending = BoxDecoration(
    color: gold.withOpacity(0.13),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: gold.withOpacity(0.55)),
  );

  static BoxDecoration statusBox(Color color) => BoxDecoration(
    color: color.withOpacity(0.13),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: color.withOpacity(0.58)),
  );

  static BoxDecoration filterBox({required bool active, required Color color}) {
    return BoxDecoration(
      color: active ? color.withOpacity(0.18) : bgDark.withOpacity(0.72),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: active ? color.withOpacity(0.95) : gold.withOpacity(0.35),
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: color.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ]
          : [],
    );
  }

  static TextStyle titleOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(
      color: textPrimary,
      fontSize: 30 * s,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle subtitleOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(color: textSecondary, fontSize: 14 * s, height: 1.35);
  }

  static TextStyle chipTextOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(
      color: gold,
      fontSize: 13 * s,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle chipNumberOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(
      color: textPrimary,
      fontSize: 13 * s,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle cardTitleOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(
      color: textPrimary,
      fontSize: 18 * s,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle smallOf(BuildContext context) {
    final s = scale(context);
    return TextStyle(color: textSecondary, fontSize: 12 * s, height: 1.25);
  }

  static const TextStyle title = TextStyle(
    color: textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle subtitle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle header = TextStyle(
    color: textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle cell = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle small = TextStyle(
    color: textSecondary,
    fontSize: 12,
    height: 1.35,
  );

  static const TextStyle goldText = TextStyle(
    color: gold,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );
}
