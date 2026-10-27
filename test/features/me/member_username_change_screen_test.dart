import 'dart:async';

import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_credentials_api.dart';
import 'package:altekamerer/features/me/member_username_change_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openEditor(
    WidgetTester tester,
    _CredentialsService service, {
    ValueNotifier<String?>? result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const ValueKey('open-username-editor'),
                onPressed: () async {
                  final username = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => MemberUsernameChangeScreen(
                        currentUsername: 'old-member',
                        credentialsService: service,
                      ),
                    ),
                  );
                  result?.value = username;
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-username-editor')));
    await tester.pumpAndSettle();
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    String username = 'new-member',
    String password = 'CurrentPassword1',
  }) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), username);
    await tester.enterText(fields.at(1), password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, 'Uppdatera användarnamn'),
    );
    await tester.pump();
  }

  testWidgets('initializes username and hides current password', (
    tester,
  ) async {
    await openEditor(tester, _CredentialsService());

    final fields = find.byType(TextFormField);

    expect(fields, findsNWidgets(2));
    expect(
      tester.widget<TextFormField>(fields.first).controller?.text,
      'old-member',
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: fields.at(1), matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );
  });

  testWidgets('successful change returns the server-confirmed username', (
    tester,
  ) async {
    final service = _CredentialsService(
      onUsernameChange: (username, password) async => 'confirmed-member',
    );
    final result = ValueNotifier<String?>(null);

    await openEditor(tester, service, result: result);
    await enterCredentials(tester);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.requests, [('new-member', 'CurrentPassword1')]);
    expect(result.value, 'confirmed-member');
    expect(find.byType(MemberUsernameChangeScreen), findsNothing);

    result.dispose();
  });

  testWidgets('required fields prevent submission', (tester) async {
    final service = _CredentialsService();

    await openEditor(tester, service);
    await enterCredentials(tester, username: '   ', password: '');
    await submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ange ett användarnamn.'), findsOneWidget);
    expect(find.text('Ange ditt nuvarande lösenord.'), findsOneWidget);
    expect(service.requests, isEmpty);
  });

  testWidgets('backend rejection preserves the form and permits retry', (
    tester,
  ) async {
    var attempts = 0;

    final service = _CredentialsService(
      onUsernameChange: (username, password) async {
        attempts++;
        if (attempts == 1) {
          throw const ApiException(
            statusCode: 400,
            message: 'InvalidCurrentPassword',
          );
        }
        return username;
      },
    );

    final result = ValueNotifier<String?>(null);

    await openEditor(tester, service, result: result);
    await enterCredentials(tester);

    await submit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Kontrollera användarnamnet och det nuvarande lösenordet och försök igen.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MemberUsernameChangeScreen), findsOneWidget);
    expect(result.value, isNull);
    expect(service.requests, hasLength(1));

    await submit(tester);
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(2));
    expect(result.value, 'new-member');

    result.dispose();
  });

  testWidgets('connection failure keeps the editor open', (tester) async {
    final service = _CredentialsService(
      onUsernameChange: (_, _) async {
        throw const ApiException(
          statusCode: 503,
          message: 'password=server-secret',
        );
      },
    );

    await openEditor(tester, service);
    await enterCredentials(tester);
    await submit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Det gick inte att ändra inloggningsuppgifterna. Försök igen.'),
      findsOneWidget,
    );
    expect(find.textContaining('server-secret'), findsNothing);
    expect(find.byType(MemberUsernameChangeScreen), findsOneWidget);
  });

  testWidgets('pending change disables duplicate submissions', (tester) async {
    final pending = Completer<String>();

    final service = _CredentialsService(
      onUsernameChange: (_, _) => pending.future,
    );

    await openEditor(tester, service);
    await enterCredentials(tester);
    await submit(tester);

    final saveButton = find.widgetWithText(
      FilledButton,
      'Uppdatera användarnamn',
    );

    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(service.requests, hasLength(1));

    pending.complete('new-member');
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(find.byType(MemberUsernameChangeScreen), findsNothing);
  });
}

class _CredentialsService implements MemberCredentialsService {
  _CredentialsService({this.onUsernameChange});

  final Future<String> Function(String, String)? onUsernameChange;

  final List<(String, String)> requests = [];

  @override
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  }) {
    requests.add((newUsername, currentPassword));

    final callback = onUsernameChange;
    if (callback != null) {
      return callback(newUsername, currentPassword);
    }

    return Future<String>.value(newUsername);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError('Password editing is not used in these tests.');
  }
}
