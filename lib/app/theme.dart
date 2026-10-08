
import 'package:flutter/material.dart';

/// Brand palette: navy accent, slate neutrals, semantic status colors,
/// light gray background.
abstract final class AppColors {
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  static const Color accentLight = Color(0xFFF2F7FD);
  static const Color accent100 = Color(0xFFE3ECF7);
  static const Color accent = Color(0xFF0F172A);
  static const Color navy = Color(0xFF062B5E);
  static const Color accentDeep = Color(0xFF071827);

  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald50 = Color(0xFFECFDF5);

  static const Color amber600 = Color(0xFFD97706);
  static const Color amber50 = Color(0xFFFFFBEB);

  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose50 = Color(0xFFFFF1F2);

  static const Color background = Color(0xFFF1F5F9);
  static const Color loginBackground = Color(0xFFF2F7FD);
  static const Color shadow = Color(0x1A102C67);
}

/// Shared type scale so screens stop hand-rolling sizes and weights.
abstract final class AppType {
  static const String display = 'Geist';
  static const String mono = 'GeistMono';

  static const TextStyle pageTitle = TextStyle(
    fontFamily: display,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.slate900,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.slate900,
  );

  static const TextStyle body = TextStyle(
    fontFamily: display,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.slate700,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: display,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.slate500,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: display,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: AppColors.slate500,
    letterSpacing: 0.4,
  );

  static const TextStyle metricValue = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.slate900,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoRef = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.slate500,
  );

  static TextStyle figures([TextStyle? style]) =>
      (style ?? body).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        secondary: AppColors.navy,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppType.display,
    );

    final textTheme = base.textTheme;

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontFamily: AppType.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
          letterSpacing: -0.2,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontFamily: AppType.display,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontFamily: AppType.display,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontFamily: AppType.display,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontFamily: AppType.display,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontFamily: AppType.display,
          fontSize: 15,
          color: AppColors.slate800,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontFamily: AppType.display,
          fontSize: 14,
          color: AppColors.slate700,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontFamily: AppType.display,
          fontSize: 12,
          color: AppColors.slate500,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontFamily: AppType.display,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.slate600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontFamily: AppType.display,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: AppColors.slate500,
          letterSpacing: 0.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppType.display,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accentLight,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppType.display,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.slate400,
            size: 22,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate300,
          disabledForegroundColor: AppColors.slate500,
          textStyle: const TextStyle(
            fontFamily: AppType.display,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: AppType.display,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: AppColors.accent100),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: AppColors.slate400,
          fontSize: 14,
          fontFamily: AppType.display,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.slate500,
          fontSize: 13,
          fontFamily: AppType.display,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rose600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rose600, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate100,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}