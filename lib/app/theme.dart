import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Switchly's visual language: restrained neutrals, crisp 1px hairlines,
/// disciplined indigo accent, and Plus Jakarta Sans throughout.
abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final scheme = dark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF7B83FF),
            onPrimary: Color(0xFF0A0C18),
            primaryContainer: Color(0xFF1D213D),
            onPrimaryContainer: Color(0xFFD9DDFF),
            secondary: Color(0xFF94A3B8),
            onSecondary: Color(0xFF0F172A),
            secondaryContainer: Color(0xFF1E222B),
            onSecondaryContainer: Color(0xFFE2E8F0),
            tertiary: Color(0xFF34D399),
            onTertiary: Color(0xFF052E16),
            error: Color(0xFFF87171),
            onError: Color(0xFF2B0B0B),
            errorContainer: Color(0xFF3B1518),
            onErrorContainer: Color(0xFFFECACA),
            surface: Color(0xFF0A0B0E),
            onSurface: Color(0xFFF3F4F6),
            onSurfaceVariant: Color(0xFF949CA9),
            surfaceContainerLowest: Color(0xFF060709),
            surfaceContainerLow: Color(0xFF121419),
            surfaceContainer: Color(0xFF181B22),
            surfaceContainerHigh: Color(0xFF20232C),
            surfaceContainerHighest: Color(0xFF292D38),
            outline: Color(0xFF343946),
            outlineVariant: Color(0xFF222630),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF3F46E5),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFECEDFE),
            onPrimaryContainer: Color(0xFF282E9E),
            secondary: Color(0xFF475569),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFEAECEF),
            onSecondaryContainer: Color(0xFF1E293B),
            tertiary: Color(0xFF16A34A),
            onTertiary: Colors.white,
            error: Color(0xFFDC2626),
            onError: Colors.white,
            errorContainer: Color(0xFFFEE2E2),
            onErrorContainer: Color(0xFF991B1B),
            surface: Color(0xFFF6F7F9),
            onSurface: Color(0xFF111318),
            onSurfaceVariant: Color(0xFF5D6472),
            surfaceContainerLowest: Color(0xFFFFFFFF),
            surfaceContainerLow: Color(0xFFFFFFFF),
            surfaceContainer: Color(0xFFEEF0F5),
            surfaceContainerHigh: Color(0xFFE5E8EF),
            surfaceContainerHighest: Color(0xFFDCE0E9),
            outline: Color(0xFFCBD2DF),
            outlineVariant: Color(0xFFE4E7EE),
          );

    final base = ThemeData(brightness: brightness, useMaterial3: true, fontFamily: fontFamily);
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.9),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.15),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelSmall: base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.15),
      bodySmall: base.textTheme.bodySmall?.copyWith(letterSpacing: 0),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45, letterSpacing: 0),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5, letterSpacing: -0.1),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final rounded12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    return base.copyWith(
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scheme.surfaceContainerLow,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: text.titleMedium?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        iconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: buttonPadding,
          shape: rounded12,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          shape: rounded12,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: rounded12, textStyle: text.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.10),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurfaceVariant.withValues(alpha: 0.4);
          }
          return states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return scheme.outlineVariant;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 2,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyMedium,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.16),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded12,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}
