import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Switchly's visual language: a deep indigo accent on quiet, slightly cool neutrals,
/// flat bordered surfaces instead of shadows, and Plus Jakarta Sans throughout.
abstract final class AppTheme {
  static const _seed = Color(0xFF4F46E5);
  static const fontFamily = 'PlusJakartaSans';

  /// Hero surfaces (setup banner, active DNS card). Same in both modes; text on it is white.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
  );

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Fidelity keeps the primary close to the seed instead of the default muted tone.
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      // Hand-tuned neutrals: soft modern dark mode, clean off-white in light mode.
      surface: dark ? const Color(0xFF0E0F14) : const Color(0xFFF8F9FC),
      surfaceContainerLowest: dark ? const Color(0xFF090A0E) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF15161E) : Colors.white,
      surfaceContainer: dark ? const Color(0xFF1B1D26) : const Color(0xFFEFF1F6),
      surfaceContainerHigh: dark ? const Color(0xFF232531) : const Color(0xFFE5E8F0),
      surfaceContainerHighest: dark ? const Color(0xFF2B2D3C) : const Color(0xFFDBDFEA),
      outlineVariant: dark ? const Color(0xFF262837) : const Color(0xFFE2E5EE),
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true, fontFamily: fontFamily);
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      // Material's default body tracking is too loose for Plus Jakarta Sans.
      bodySmall: base.textTheme.bodySmall?.copyWith(letterSpacing: 0),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45, letterSpacing: 0),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5, letterSpacing: -0.1),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final rounded16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 14);

    return base.copyWith(
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        iconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(padding: buttonPadding, shape: rounded16, textStyle: text.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: rounded16,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: rounded16, textStyle: text.labelLarge),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Icon(Icons.check_rounded, size: 16, color: scheme.primary) : null,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: rounded16,
        textStyle: text.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded16,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}
