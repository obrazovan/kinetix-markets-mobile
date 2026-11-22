import 'package:material_ui/material_ui.dart';

/// Custom color tokens for Obsidian Tape (dark) and Ivory Ledger (light) modes.
@immutable
class TerminalPalette extends ThemeExtension<TerminalPalette> {
  const TerminalPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.bull,
    required this.bear,
    required this.accent,
    required this.warning,
    required this.gridLine,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color bull;
  final Color bear;
  final Color accent;
  final Color warning;
  final Color gridLine;

  static const obsidian = TerminalPalette(
    canvas: Color(0xFF0A0E14),
    surface: Color(0xFF121822),
    surfaceElevated: Color(0xFF1A2230),
    border: Color(0xFF232E40),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF8B99AE),
    bull: Color(0xFF00D084),
    bear: Color(0xFFFF4D6A),
    accent: Color(0xFF38BDF8),
    warning: Color(0xFFF5A623),
    gridLine: Color(0xFF1D2636),
  );

  static const ivory = TerminalPalette(
    canvas: Color(0xFFF4F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEEF2F7),
    border: Color(0xFFDCE3ED),
    textPrimary: Color(0xFF0E1726),
    textSecondary: Color(0xFF5A687E),
    bull: Color(0xFF009B63),
    bear: Color(0xFFD9304E),
    accent: Color(0xFF0284C7),
    warning: Color(0xFFD97706),
    gridLine: Color(0xFFE3E8F0),
  );

  @override
  TerminalPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? bull,
    Color? bear,
    Color? accent,
    Color? warning,
    Color? gridLine,
  }) {
    return TerminalPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      bull: bull ?? this.bull,
      bear: bear ?? this.bear,
      accent: accent ?? this.accent,
      warning: warning ?? this.warning,
      gridLine: gridLine ?? this.gridLine,
    );
  }

  @override
  TerminalPalette lerp(ThemeExtension<TerminalPalette>? other, double t) {
    if (other is! TerminalPalette) return this;
    return TerminalPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      bull: Color.lerp(bull, other.bull, t)!,
      bear: Color.lerp(bear, other.bear, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
    );
  }
}

/// Centralized ThemeData factory with tabular monospace financial numerals.
abstract final class TerminalTheme {
  static TextStyle tabular(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    final palette = of(context);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? palette.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.2,
    );
  }

  static TerminalPalette of(BuildContext context) {
    return Theme.of(context).extension<TerminalPalette>() ??
        TerminalPalette.obsidian;
  }

  static ThemeData build({required bool isDark}) {
    final p = isDark ? TerminalPalette.obsidian : TerminalPalette.ivory;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: isDark ? const Color(0xFF04131E) : Colors.white,
        secondary: p.bull,
        onSecondary: Colors.white,
        error: p.bear,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? p.accent : p.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? p.accent : p.textSecondary,
            size: 22,
          );
        }),
      ),
      dividerColor: p.border,
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }
}
