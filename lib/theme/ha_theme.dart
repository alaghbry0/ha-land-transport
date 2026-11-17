import 'package:flutter/material.dart';

/// هوية HA للنقل البري البصرية.
///
/// - كحلي داكن #0F172A كلون رئيسي (خلفيات داكنة/الأسطح العلوية).
/// - أخضر زمردي #10B981 للأزرار التفاعلية والحالات النشطة.
/// - بطاقات فاتحة نظيفة بظلال ناعمة على خلفية رمادية فاتحة.
abstract final class HaColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color navySoft = Color(0xFF1E293B);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color white = Colors.white;
}

/// ظل بطاقة ناعم موحّد.
List<BoxShadow> softShadow({double opacity = 0.08}) => [
      BoxShadow(
        color: HaColors.navy.withValues(alpha: opacity),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];

/// بناء ThemeData للتطبيق — Material 3 مع خط IBM Plex Sans Arabic.
ThemeData buildHaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HaColors.emerald,
    primary: HaColors.emerald,
    onPrimary: Colors.white,
    secondary: HaColors.navy,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: HaColors.navy,
    surfaceContainerHighest: HaColors.slate100,
    error: HaColors.red,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: HaColors.slate50,
    textTheme: _buildTextTheme(base.textTheme).apply(fontFamily: 'IBM Plex Sans Arabic'),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: HaColors.navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: HaColors.navy,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HaColors.emerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HaColors.navy,
        side: const BorderSide(color: HaColors.slate300, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HaColors.slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HaColors.emerald, width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      hintStyle: const TextStyle(color: HaColors.slate400, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: HaColors.navy,
      contentTextStyle: TextStyle(
        fontFamily: 'IBM Plex Sans Arabic',
        fontSize: 14,
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: HaColors.slate200, thickness: 1),
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  return base.apply(
    bodyColor: HaColors.navy,
    displayColor: HaColors.navy,
    fontFamily: 'IBM Plex Sans Arabic',
  ).copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w700,
      color: HaColors.navy,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w700,
      color: HaColors.navy,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w700,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w600,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontSize: 15.5,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontSize: 14,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontSize: 12.5,
      color: HaColors.slate500,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontFamily: 'IBM Plex Sans Arabic',
      fontWeight: FontWeight.w700,
    ),
  );
}
