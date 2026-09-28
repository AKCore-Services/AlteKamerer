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
    expect(theme.progressIndicatorTheme.color, AkColors.accessibleRed);
  });

  test('surface accent red meets normal-text contrast target', () {
    expect(
      _contrastRatio(AkColors.accessibleRed, AkColors.grey),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('input border red meets non-text contrast target', () {
    expect(
      _contrastRatio(AkColors.accessibleBorderRed, AkColors.grey),
      greaterThanOrEqualTo(3),
    );
  });

  test('primary filled controls retain branded high-contrast colors', () {
    final theme = AppTheme.dark;
    final states = <WidgetState>{};

    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve(states),
      AkColors.red,
    );
    expect(
      theme.filledButtonTheme.style?.foregroundColor?.resolve(states),
      AkColors.white,
    );
  });

  test('button themes provide at least 48 logical pixel touch height', () {
    final theme = AppTheme.dark;
    final states = <WidgetState>{};

    final minimumSizes = [
      theme.elevatedButtonTheme.style?.minimumSize?.resolve(states),
      theme.filledButtonTheme.style?.minimumSize?.resolve(states),
      theme.outlinedButtonTheme.style?.minimumSize?.resolve(states),
    ];

    for (final size in minimumSizes) {
      expect(size, isNotNull);
      expect(size!.height, greaterThanOrEqualTo(48));
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();

  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
