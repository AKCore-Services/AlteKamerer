import 'package:flutter/material.dart';

import 'ak_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final baseTextTheme = baseTheme.textTheme;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AkColors.red,
          brightness: Brightness.dark,
          surface: AkColors.grey,
        ).copyWith(
          primary: AkColors.red,
          onPrimary: AkColors.white,
          secondary: AkColors.lightGrey,
          onSecondary: AkColors.black,
          surface: AkColors.grey,
          onSurface: AkColors.white,
        );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AkColors.black,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AkColors.red,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AkColors.red,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: AkColors.red,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AkColors.red,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AkColors.lightGrey,
          fontWeight: FontWeight.w300,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AkColors.lightGrey,
          fontWeight: FontWeight.w300,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AkColors.lightGrey,
          fontWeight: FontWeight.w300,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: AkColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AkColors.red,
          foregroundColor: AkColors.white,
          disabledBackgroundColor: AkColors.deepRed,
          disabledForegroundColor: AkColors.lightGrey,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AkColors.red,
          foregroundColor: AkColors.white,
          disabledBackgroundColor: AkColors.deepRed,
          disabledForegroundColor: AkColors.lightGrey,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AkColors.white,
          side: const BorderSide(color: AkColors.red),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AkColors.grey,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AkColors.deepRed),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AkColors.grey,
        labelStyle: const TextStyle(color: AkColors.lightGrey),
        hintStyle: const TextStyle(color: AkColors.lightGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AkColors.deepRed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AkColors.deepRed),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AkColors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AkColors.grey,
        indicatorColor: AkColors.red,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AkColors.white
                : AkColors.lightGrey,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w500
                : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AkColors.white
                : AkColors.lightGrey,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AkColors.red,
        linearTrackColor: AkColors.grey,
      ),
      dividerColor: AkColors.deepRed,
    );
  }
}
