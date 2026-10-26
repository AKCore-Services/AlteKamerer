import 'dart:async';

import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_credentials_api.dart';
import 'package:altekamerer/features/me/member_password_change_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openEditor(
    WidgetTester tester,
    _CredentialsService service,
    _OutcomeCapture capture,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const ValueKey('open-password-editor'),
                onPressed: () async {
                  capture.outcome = await Navigator.of(context)
                      .push<PasswordChangeOutcome>(
                        MaterialPageRoute(
                          builder: (_) => MemberPasswordChangeScreen(
                            credentialsService: service,
                          ),
                        ),
                      );
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-password-editor')));
    await tester.pumpAndSettle();
  }

  Future<void> enterPasswords(
    WidgetTester tester, {
    String current = 'CurrentPassword1',
    String next = 'NewPassword2',
    String confirmation = 'NewPassword2',
  }) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), next);
    await tester.enterText(fields.at(2), confirmation);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Uppdatera lösenord'));
    await tester.pump();
  }

  testWidgets('password fields are obscured', (tester) async {
    await openEditor(tester, _CredentialsService(), _OutcomeCapture());

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));

    for (var i = 0; i < 3; i++) {
      final field = find.descendant(
        of: fields.at(i),
        matching: find.byType(TextField),
      );

      expect(tester.widget<TextField>(field).obscureText, isTrue);
    }

    expect(find.textContaining('Du behöver logga in igen'), findsOneWidget);
  });

  testWidgets('empty passwords prevent submission', (tester) async {
    final service = _CredentialsService();

    await openEditor(tester, service, _OutcomeCapture());
    await submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ange ditt nuvarande lösenord.'), findsOneWidget);
    expect(find.text('Ange ditt lösenord.'), findsNWidgets(2));
    expect(service.passwordRequests, isEmpty);
  });

  testWidgets('short and mismatched passwords are rejected locally', (
    tester,
  ) async {
    final service = _CredentialsService();

    await openEditor(tester, service, _OutcomeCapture());

    await enterPasswords(tester, next: 'short', confirmation: 'different');

    await submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Använd minst 6 tecken.'), findsOneWidget);
    expect(find.text('Lösenorden stämmer inte överens.'), findsOneWidget);
    expect(service.passwordRequests, isEmpty);
  });

  testWidgets('successful change returns confirmed outcome', (tester) async {
    final service = _CredentialsService();
    final capture = _OutcomeCapture();

    await openEditor(tester, service, capture);
    await enterPasswords(tester);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.passwordRequests, [('CurrentPassword1', 'NewPassword2')]);
    expect(capture.outcome, PasswordChangeOutcome.changed);
    expect(find.byType(MemberPasswordChangeScreen), findsNothing);
  });

  testWidgets('HTTP 400 preserves form and supports correction', (
    tester,
  ) async {
    var attempts = 0;

    final service = _CredentialsService(
      onPasswordChange: (_, _) async {
        attempts++;
        if (attempts == 1) {
          throw const ApiException(
            statusCode: 400,
            message: 'InvalidCurrentPassword',
          );
        }
      },
    );

    final capture = _OutcomeCapture();

    await openEditor(tester, service, capture);
    await enterPasswords(tester);

    await submit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Kontrollera ditt nuvarande och nya lösenord och försök igen.'),
      findsOneWidget,
    );
    expect(capture.outcome, isNull);
    expect(service.passwordRequests, hasLength(1));

    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.passwordRequests, hasLength(2));
    expect(capture.outcome, PasswordChangeOutcome.changed);
  });

  for (final status in [401, 408, 503]) {
    testWidgets('HTTP $status requires sign-in with uncertain outcome', (
      tester,
    ) async {
      final service = _CredentialsService(
        onPasswordChange: (_, _) async {
          throw ApiException(
            statusCode: status,
            message: 'password=server-secret',
          );
        },
      );

      final capture = _OutcomeCapture();

      await openEditor(tester, service, capture);
      await enterPasswords(tester);
      await submit(tester);
      await tester.pumpAndSettle();

      expect(service.passwordRequests, hasLength(1));
      expect(capture.outcome, PasswordChangeOutcome.unconfirmed);
      expect(find.byType(MemberPasswordChangeScreen), findsNothing);
      expect(find.textContaining('server-secret'), findsNothing);
    });
  }

  testWidgets('unexpected failure requires sign-in', (tester) async {
    final service = _CredentialsService(
      onPasswordChange: (_, _) async {
        throw StateError('Connection interrupted');
      },
    );

    final capture = _OutcomeCapture();

    await openEditor(tester, service, capture);
    await enterPasswords(tester);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(capture.outcome, PasswordChangeOutcome.unconfirmed);
    expect(find.byType(MemberPasswordChangeScreen), findsNothing);
  });

  testWidgets('pending change prevents duplicate submissions', (tester) async {
    final pending = Completer<void>();

    final service = _CredentialsService(
      onPasswordChange: (_, _) => pending.future,
    );

    final capture = _OutcomeCapture();

    await openEditor(tester, service, capture);
    await enterPasswords(tester);
    await submit(tester);

    final saveButton = find.widgetWithText(FilledButton, 'Uppdatera lösenord');

    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(service.passwordRequests, hasLength(1));

    pending.complete();
    await tester.pumpAndSettle();

    expect(service.passwordRequests, hasLength(1));
    expect(capture.outcome, PasswordChangeOutcome.changed);
  });
}

class _OutcomeCapture {
  PasswordChangeOutcome? outcome;
}

class _CredentialsService implements MemberCredentialsService {
  _CredentialsService({this.onPasswordChange});

  final Future<void> Function(String, String)? onPasswordChange;

  final List<(String, String)> passwordRequests = [];

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordRequests.add((currentPassword, newPassword));

    final callback = onPasswordChange;
    if (callback != null) {
      await callback(currentPassword, newPassword);
    }
  }

  @override
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  }) async {
    throw UnsupportedError('Username changes are not used in these tests.');
  }
}
