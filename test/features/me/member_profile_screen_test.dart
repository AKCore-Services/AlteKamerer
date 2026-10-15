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
}

class _FakeProfileService implements MemberProfileService {
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
