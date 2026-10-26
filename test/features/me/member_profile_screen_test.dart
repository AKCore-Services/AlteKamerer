import 'dart:async';

import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_profile.dart';
import 'package:altekamerer/features/me/member_profile_api.dart';
import 'package:altekamerer/features/me/member_profile_controller.dart';
import 'package:altekamerer/features/me/member_profile_preview_service.dart';
import 'package:altekamerer/features/me/member_profile_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = MemberProfile(
    userName: 'testmedlem',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'Testsson',
    phone: '070-1234567',
    instrument: 'Trumpet',
    otherInstruments: ['Trombon'],
    roles: ['Medlem'],
    posts: ['Materialförvaltare'],
    medal: 'Silver',
    givenMedal: 'Brons',
  );

  const statistics = MemberProfileStatistics(
    totalGigs: 20,
    halan: 8,
    direct: 6,
    cantCome: 4,
    car: 3,
    instrument: 5,
    comment: 2,
  );

  Future<void> showProfile(
    WidgetTester tester,
    MemberProfileController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MemberProfileScreen(controller: controller)),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    final editButton = find.widgetWithText(OutlinedButton, 'Uppdatera profil');

    await tester.scrollUntilVisible(
      editButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(editButton);
    await tester.pumpAndSettle();
  }

  Future<void> submitEditor(WidgetTester tester) async {
    final saveButton = find.widgetWithText(FilledButton, 'Spara ändringar');

    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find
          .ancestor(
            of: find.byType(TextFormField).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(saveButton);
    await tester.pump();
  }

  const updatedProfile = MemberProfile(
    userName: 'testmedlem',
    email: 'updated@example.com',
    firstName: 'Updated',
    lastName: 'Member',
    phone: '0709876543',
    instrument: 'Klarinett',
    otherInstruments: ['Flöjt', 'Trombon'],
    roles: ['Medlem'],
    posts: ['Materialförvaltare'],
    medal: 'Silver',
    givenMedal: 'Brons',
  );

  testWidgets('displays authenticated member information', (tester) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);

    expect(find.text('Test Testsson'), findsOneWidget);
    expect(find.text('testmedlem'), findsWidgets);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Trumpet'), findsOneWidget);
    expect(find.text('Trombon'), findsOneWidget);

    expect(controller.isProfilePreview, isFalse);
    expect(find.textContaining('Testdata'), findsNothing);
  });

  testWidgets('labels placeholder information in the test app', (tester) async {
    final service = MemberProfilePreviewService(
      _FakeProfileService(
        profileError: const ApiException(statusCode: 404, message: 'Not found'),
      ),
      allowPreview: true,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);

    expect(find.text('Förnamn Efternamn'), findsOneWidget);
    expect(find.textContaining('Testdata'), findsOneWidget);
    expect(controller.isProfilePreview, isTrue);
  });

  testWidgets('does not show placeholders for authentication failures', (
    tester,
  ) async {
    final service = MemberProfilePreviewService(
      _FakeProfileService(
        profileError: const ApiException(
          statusCode: 401,
          message: 'Unauthorized',
        ),
      ),
      allowPreview: true,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);

    expect(controller.status, MemberProfileStatus.error);
    expect(
      find.text('Profilinformationen är inte tillgänglig.'),
      findsOneWidget,
    );
    expect(find.text('Förnamn Efternamn'), findsNothing);
    expect(find.textContaining('Testdata'), findsNothing);
  });

  testWidgets('displays AKCore registration statistics in a dialog', (
    tester,
  ) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);

    final statisticsButton = find.widgetWithText(FilledButton, 'Statistik');

    await tester.scrollUntilVisible(
      statisticsButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(statisticsButton);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Anmälningsval'), findsOneWidget);
    expect(
      find.textContaining('Registreringsstatistik från AKCore'),
      findsOneWidget,
    );
    expect(find.text('20'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(controller.statistics?.totalGigs, 20);
  });

  testWidgets('saves permitted edits and updates the Me page', (tester) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
      onUpdate: (_) async => updatedProfile,
    );

    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    final fields = find.byType(TextFormField);

    expect(fields, findsNWidgets(6));
    expect(tester.widget<TextFormField>(fields.at(0)).controller?.text, 'Test');
    expect(
      tester.widget<TextFormField>(fields.at(5)).controller?.text,
      'Trombon',
    );

    await tester.enterText(fields.at(0), 'Updated');
    await tester.enterText(fields.at(1), 'Member');
    await tester.enterText(fields.at(2), 'updated@example.com');
    await tester.enterText(fields.at(3), '0709876543');
    await tester.enterText(fields.at(4), 'Klarinett');
    await tester.enterText(fields.at(5), 'Flöjt, Trombon');

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));

    final request = service.requests.single;

    expect(request.firstName, 'Updated');
    expect(request.lastName, 'Member');
    expect(request.email, 'updated@example.com');
    expect(request.phone, '0709876543');
    expect(request.instrument, 'Klarinett');
    expect(request.otherInstruments, ['Flöjt', 'Trombon']);

    expect(controller.profile, same(updatedProfile));
    expect(find.text('Profil uppdaterad'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Updated Member'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Updated Member'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('updated@example.com'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('updated@example.com'), findsOneWidget);
  });

  testWidgets('cancel discards edits without submitting changes', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );

    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Discarded');

    final cancelButton = find.widgetWithText(OutlinedButton, 'Avbryt');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      cancelButton,
      200,
      scrollable: find
          .ancestor(
            of: find.byType(TextFormField).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(controller.profile, same(profile));
    expect(find.byType(TextFormField), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Test Testsson'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Test Testsson'), findsOneWidget);
    expect(find.text('Discarded'), findsNothing);
  });

  testWidgets('duplicate instruments are rejected before submission', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );

    await showProfile(tester, MemberProfileController(service));

    await openEditor(tester);

    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Trombon, Trumpet',
    );

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);

    final otherInstrumentsDecorator = find.descendant(
      of: find.byType(TextFormField).at(5),
      matching: find.byType(InputDecorator),
    );

    expect(
      tester
          .widget<InputDecorator>(otherInstrumentsDecorator)
          .decoration
          .errorMaxLines,
      4,
    );
    expect(find.textContaining('Huvudinstrumentet kan inte'), findsOneWidget);
  });

  testWidgets('invalid email highlights the email field', (tester) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);
    await openEditor(tester);

    final emailField = find.byType(TextFormField).at(2);

    await tester.enterText(emailField, 'not-an-email');
    await tester.pumpAndSettle();

    const message = 'Ange en giltig e-postadress.';

    expect(find.text(message), findsOneWidget);

    final decoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: emailField,
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;

    expect(decoration.errorText, message);

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(find.text('Spara ändringar'), findsOneWidget);
  });

  testWidgets('email domain suggestions do not invalidate the field', (
    tester,
  ) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);
    await openEditor(tester);

    final emailField = find.byType(TextFormField).at(2);

    await tester.enterText(emailField, 'member@gmail');
    await tester.pumpAndSettle();

    expect(
      find.text('Menade du gmail.com? Du kan fortfarande spara adressen.'),
      findsOneWidget,
    );

    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: emailField,
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .errorText,
      isNull,
    );

    await tester.enterText(emailField, 'member@mycompany.se');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('E-postdomänen finns inte bland vanliga'),
      findsOneWidget,
    );

    await tester.enterText(emailField, 'member@gmail.com');
    await tester.pumpAndSettle();

    expect(find.textContaining('Menade du'), findsNothing);
    expect(
      find.textContaining('E-postdomänen finns inte bland vanliga'),
      findsNothing,
    );
  });

  testWidgets('primary instrument offers localized suggestions', (
    tester,
  ) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);
    await openEditor(tester);

    final primary = find.byType(TextFormField).at(4);

    await tester.enterText(primary, 'Flu');
    await tester.pumpAndSettle();

    final suggestion = find.text('Flöjt');
    expect(suggestion, findsOneWidget);

    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(tester.widget<TextFormField>(primary).controller?.text, 'Flöjt');
  });

  testWidgets('additional suggestion preserves preceding instruments', (
    tester,
  ) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);
    await openEditor(tester);

    final additional = find.byType(TextFormField).at(5);

    await tester.enterText(additional, 'Trombon, Flu');
    await tester.pumpAndSettle();

    final suggestion = find.text('Flöjt');
    expect(suggestion, findsOneWidget);

    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(additional).controller?.text,
      'Trombon, Flöjt',
    );
  });

  testWidgets('custom instruments display a nonblocking warning', (
    tester,
  ) async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'Nyckelharpa');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Detta är inte ett standardinstrument'),
      findsOneWidget,
    );

    final saveButton = find.widgetWithText(FilledButton, 'Spara ändringar');

    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find
          .ancestor(
            of: find.byType(TextFormField).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(saveButton, findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('saves English instrument names as canonical values', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'Trombone');
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Flute, Accordion',
    );

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(service.requests.single.instrument, 'Trombon');
    expect(service.requests.single.otherInstruments, ['Flöjt', 'Dragspel']);
  });

  testWidgets('preserves custom instrument names when saving', (tester) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'Nyckelharpa');
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Baritone sax, Didgeridoo',
    );

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(service.requests.single.instrument, 'Nyckelharpa');
    expect(service.requests.single.otherInstruments, [
      'Barytonsax',
      'Didgeridoo',
    ]);
  });

  testWidgets('rejects mixed-language duplicate instruments', (tester) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'Trombone');
    await tester.enterText(find.byType(TextFormField).at(5), 'Trombon');

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(
      find.text(
        'Huvudinstrumentet kan inte även finnas bland övriga instrument.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rejects custom primary instrument duplicates ignoring case', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(find.byType(TextFormField).at(4), 'Nyckelharpa');
    await tester.enterText(find.byType(TextFormField).at(5), 'nyckelharpa');

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(
      find.text(
        'Huvudinstrumentet kan inte även finnas bland övriga instrument.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rejects translated duplicates within other instruments', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Trombone, Trombon',
    );

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(
      find.text(
        'Samma instrument kan inte anges flera gånger bland övriga instrument.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rejects repeated custom instruments ignoring case', (
    tester,
  ) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
    );
    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Nyckelharpa, nyckelharpa',
    );

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(
      find.text(
        'Samma instrument kan inte anges flera gånger bland övriga instrument.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('server rejection keeps the editing form open', (tester) async {
    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
      onUpdate: (_) async {
        throw const ApiException(statusCode: 400, message: 'Request failed.');
      },
    );

    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await submitEditor(tester);
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(controller.profile, same(profile));
    expect(controller.isSaving, isFalse);
    expect(controller.saveError, isA<ApiException>());

    expect(
      find.text('Kontrollera profiluppgifterna och försök igen.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Spara ändringar'),
      findsOneWidget,
    );
  });

  testWidgets('preview profiles do not offer editing', (tester) async {
    final previewService = MemberProfilePreviewService(
      _FakeProfileService(
        profileError: const ApiException(statusCode: 404, message: 'Not found'),
      ),
      allowPreview: true,
    );

    final controller = MemberProfileController(previewService);

    await showProfile(tester, controller);

    expect(controller.isProfilePreview, isTrue);
    expect(
      find.widgetWithText(OutlinedButton, 'Uppdatera profil'),
      findsNothing,
    );
  });

  testWidgets('logout during saving cannot restore profile information', (
    tester,
  ) async {
    final pending = Completer<MemberProfile>();

    final service = _EditingProfileService(
      profile: profile,
      statistics: statistics,
      onUpdate: (_) => pending.future,
    );

    final controller = MemberProfileController(service);

    await showProfile(tester, controller);
    await openEditor(tester);

    await submitEditor(tester);

    expect(controller.isSaving, isTrue);
    expect(service.requests, hasLength(1));

    controller.clear();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    pending.complete(updatedProfile);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.status, MemberProfileStatus.idle);
    expect(controller.profile, isNull);
    expect(controller.isSaving, isFalse);
    expect(controller.saveError, isNull);
    expect(find.text('Updated Member'), findsNothing);
  });
}

class _EditingProfileService implements MemberProfileService {
  _EditingProfileService({
    required this.profile,
    required this.statistics,
    this.onUpdate,
  });

  final MemberProfile profile;
  final MemberProfileStatistics statistics;
  final Future<MemberProfile> Function(MemberProfileUpdateRequest)? onUpdate;

  final List<MemberProfileUpdateRequest> requests = [];

  @override
  Future<MemberProfile> getProfile() async => profile;

  @override
  Future<MemberProfileStatistics> getStatistics() async => statistics;

  @override
  Future<MemberProfile> updateProfile(MemberProfileUpdateRequest request) {
    requests.add(request);

    return onUpdate?.call(request) ?? Future<MemberProfile>.value(profile);
  }
}

class _FakeProfileService implements MemberProfileService {
  @override
  Future<MemberProfile> updateProfile(
    MemberProfileUpdateRequest request,
  ) async {
    throw UnimplementedError(
      'Profile editing is not configured in this test fake.',
    );
  }

  const _FakeProfileService({this.profile, this.statistics, this.profileError});

  final MemberProfile? profile;
  final MemberProfileStatistics? statistics;
  final Object? profileError;

  @override
  Future<MemberProfile> getProfile() async {
    if (profileError != null) {
      throw profileError!;
    }

    return profile!;
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    return statistics!;
  }
}
