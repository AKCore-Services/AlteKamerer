import 'package:altekamerer/core/theme/ak_colors.dart';
import 'package:altekamerer/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme uses AKCore brand colors', () {
    final theme = AppTheme.dark;

    expect(theme.colorScheme.primary, AkColors.red);
    expect(theme.colorScheme.surface, AkColors.grey);
    expect(theme.scaffoldBackgroundColor, AkColors.black);
    expect(theme.colorScheme.onSurface, AkColors.white);
  });

  test('theme reproduces AKCore typography weight cues', () {
    final textTheme = AppTheme.dark.textTheme;

    expect(textTheme.headlineMedium?.fontWeight, FontWeight.w500);
    expect(textTheme.bodyMedium?.fontWeight, FontWeight.w300);
    expect(textTheme.labelLarge?.fontWeight, FontWeight.w500);
  });

  test('theme provides reusable branded component styling', () {
    final theme = AppTheme.dark;

    expect(theme.elevatedButtonTheme.style, isNotNull);
    expect(theme.filledButtonTheme.style, isNotNull);
    expect(theme.outlinedButtonTheme.style, isNotNull);
    expect(theme.cardTheme.color, AkColors.grey);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.navigationBarTheme.backgroundColor, AkColors.grey);
    expect(theme.progressIndicatorTheme.color, AkColors.red);
  });
}
