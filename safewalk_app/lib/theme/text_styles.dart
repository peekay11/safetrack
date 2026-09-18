import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Quicksand = headings / brand moments. Inter = body copy.
class SWText {
  SWText._();

  static TextStyle quicksand({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = SWColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.quicksand(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle inter({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = SWColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
