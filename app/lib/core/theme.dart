import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Brand {
  // Palette tirée de l'affiche : noir profond + or + flamme
  static const ink = Color(0xFF0A0806);
  static const surface = Color(0xFF14100B);
  static const card = Color(0xFF1B150F);
  static const line = Color(0xFF2D2318);
  static const gold = Color(0xFFF2C230);
  static const goldDeep = Color(0xFFD99A12);
  static const goldSoft = Color(0xFFFFE08A);
  static const flame = Color(0xFFE2571F);
  static const cream = Color(0xFFFFF4DC);
  static const dim = Color(0xFFB8AB95);
  static const ok = Color(0xFF3DDC84);
  static const danger = Color(0xFFFF6B5E);

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFAD35A), Color(0xFFE0A417)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const flameGradient = LinearGradient(
    colors: [Color(0xFFEA5A1B), Color(0xFFC9840B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Police des titres (condensée, comme le logo).
  static TextStyle display(double size, {Color color = cream, double spacing = 0.6, double? height}) =>
      GoogleFonts.anton(fontSize: size, color: color, letterSpacing: spacing, height: height);

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final text = GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: cream, displayColor: cream);
    return base.copyWith(
      scaffoldBackgroundColor: ink,
      textTheme: text,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      }),
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: ink,
        secondary: flame,
        surface: surface,
        onSurface: cream,
        error: danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: cream,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: display(21, color: gold, spacing: 1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFF0E0B08),
        indicatorColor: gold.withOpacity(0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? gold : dim,
            )),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? gold : dim)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        labelStyle: const TextStyle(color: dim),
        hintStyle: const TextStyle(color: dim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gold, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          disabledBackgroundColor: line,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: BorderSide(color: gold.withOpacity(0.7)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: card,
        selectedColor: gold,
        side: const BorderSide(color: line),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: cream),
        secondaryLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: card,
        contentTextStyle: GoogleFonts.poppins(color: cream, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: line)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ink : dim),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? gold : line),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
    );
  }
}
