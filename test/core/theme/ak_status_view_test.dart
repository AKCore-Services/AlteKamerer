import 'package:altekamerer/core/theme/ak_brand_logo.dart';
import 'package:altekamerer/core/theme/ak_status_view.dart';
import 'package:altekamerer/core/theme/app_theme.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading view uses branded mark and progress indicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AkLoadingView()),
      ),
    );

    final logo = tester.widget<AkBrandLogo>(find.byType(AkBrandLogo));

    expect(logo.variant, AkBrandLogoVariant.mark);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error view shows title and message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: AkErrorView(
            title: 'Något gick fel',
            message: 'Det gick inte att hämta informationen.',
          ),
        ),
      ),
    );

    expect(find.text('Något gick fel'), findsOneWidget);
    expect(find.text('Det gick inte att hämta informationen.'), findsOneWidget);
    expect(find.text('Försök igen'), findsNothing);
  });

  testWidgets('error view exposes retry action when provided', (
    WidgetTester tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AkErrorView(
            title: 'Något gick fel',
            message: 'Försök igen.',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Försök igen'), findsOneWidget);

    await tester.tap(find.text('Försök igen'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
