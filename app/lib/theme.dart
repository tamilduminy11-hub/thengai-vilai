import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette shared with the static web page: palm-leaf green header,
/// coconut-husk brown for headings and the chart line.
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.leaf,
    required this.leafInk,
    required this.husk,
    required this.up,
    required this.upBg,
    required this.down,
    required this.downBg,
    required this.flatBg,
    required this.grid,
  });

  final Color bg, surface, ink, ink2, ink3, line, leaf, leafInk, husk, up, upBg, down, downBg, flatBg, grid;

  static const light = Palette(
    bg: Color(0xFFF3F5EF), surface: Color(0xFFFFFFFF), ink: Color(0xFF1D261D), ink2: Color(0xFF4F5B4E),
    ink3: Color(0xFF7A8578), line: Color(0xFFDDE3D6), leaf: Color(0xFF24452C), leafInk: Color(0xFFF1F6EE),
    husk: Color(0xFF7A4A21), up: Color(0xFF17763A), upBg: Color(0xFFE3F2E6), down: Color(0xFFB3261E),
    downBg: Color(0xFFF9E4E2), flatBg: Color(0xFFECEEE8), grid: Color(0xFFE4E8DE),
  );

  static const dark = Palette(
    bg: Color(0xFF111511), surface: Color(0xFF1A201A), ink: Color(0xFFE8EDE4), ink2: Color(0xFFB6C0B2),
    ink3: Color(0xFF8A9586), line: Color(0xFF2C352B), leaf: Color(0xFF1C3622), leafInk: Color(0xFFE8F2E3),
    husk: Color(0xFFE0A76F), up: Color(0xFF6FCF8B), upBg: Color(0xFF183A22), down: Color(0xFFF08A80),
    downBg: Color(0xFF44201C), flatBg: Color(0xFF252C24), grid: Color(0xFF2A3229),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) => t < 0.5 ? this : (other as Palette? ?? this);
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: p.leaf, brightness: b, surface: p.surface),
    scaffoldBackgroundColor: p.bg,
    fontFamily: GoogleFonts.catamaran().fontFamily,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    extensions: [p],
  );
}

extension PaletteX on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
}
