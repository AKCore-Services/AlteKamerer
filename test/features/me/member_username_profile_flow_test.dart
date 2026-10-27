import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_credentials_api.dart';
import 'package:altekamerer/features/me/member_profile.dart';
import 'package:altekamerer/features/me/member_profile_api.dart';
import 'package:altekamerer/features/me/member_profile_controller.dart';
import 'package:altekamerer/features/me/member_profile_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showProfile(
    WidgetTester tester,
    _ProfileService profileService,
    _CredentialsService credentialsService,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemberProfileScreen(
            controller: MemberProfileController(profileService),
            credentialsService: credentialsService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> openUsernameEditor(WidgetTester tester) async {
    final button = find.byTooltip('Ändra användarnamn');

    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> submitUsernameChange(WidgetTester tester) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'new-member');
    await tester.enterText(fields.at(1), 'CurrentPassword1');

    await tester.tap(
      find.widgetWithText(FilledButton, 'Uppdatera användarnamn'),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('successful username change refreshes Me profile', (
    tester,
  ) async {
    final profileService = _ProfileService();
    final credentialsService = _CredentialsService(profileService);

    await showProfile(tester, profileService, credentialsService);

    expect(find.text('old-member'), findsWidgets);
    expect(profileService.loadCalls, 1);

    await openUsernameEditor(tester);
    await submitUsernameChange(tester);

    expect(credentialsService.changeCalls, 1);
    expect(credentialsService.requestedUsername, 'new-member');
    expect(credentialsService.currentPassword, 'CurrentPassword1');

    expect(profileService.loadCalls, 2);

    // Return to the top before checking the displayed username.
    final profileScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    profileScroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('new-member'), findsWidgets);
    expect(find.text('old-member'), findsNothing);

    expect(find.text('Användarnamnet har uppdaterats'), findsOneWidget);

    expect(find.byType(MemberProfileScreen), findsOneWidget);
  });

  testWidgets('rejected username change preserves Me profile', (tester) async {
    final profileService = _ProfileService();
    final credentialsService = _CredentialsService(
      profileService,
      rejectChange: true,
    );

    await showProfile(tester, profileService, credentialsService);

    expect(profileService.loadCalls, 1);

    await openUsernameEditor(tester);
    await submitUsernameChange(tester);

    expect(credentialsService.changeCalls, 1);
    expect(profileService.loadCalls, 1);
    expect(profileService.username, 'old-member');

    expect(
      find.text(
        'Kontrollera användarnamnet och det nuvarande lösenordet och försök igen.',
      ),
      findsOneWidget,
    );

    expect(find.text('Användarnamnet har uppdaterats'), findsNothing);
  });
}

class _ProfileService implements MemberProfileService {
  String username = 'old-member';
  int loadCalls = 0;

  @override
  Future<MemberProfile> getProfile() async {
    loadCalls++;

    return MemberProfile(
      userName: username,
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'Testsson',
      phone: '',
      instrument: 'Trumpet',
      otherInstruments: const [],
      roles: const ['Medlem'],
      posts: const [],
      medal: '',
      givenMedal: '',
    );
  }

  @override
  Future<MemberProfile> updateProfile(
    MemberProfileUpdateRequest request,
  ) async {
    throw UnsupportedError('Not used in username-change tests.');
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    return const MemberProfileStatistics(
      totalGigs: 0,
      halan: 0,
      direct: 0,
      cantCome: 0,
      car: 0,
      instrument: 0,
      comment: 0,
    );
  }
}

class _CredentialsService implements MemberCredentialsService {
  _CredentialsService(this.profileService, {this.rejectChange = false});

  final _ProfileService profileService;
  final bool rejectChange;

  int changeCalls = 0;
  String? requestedUsername;
  String? currentPassword;

  @override
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  }) async {
    changeCalls++;
    requestedUsername = newUsername;
    this.currentPassword = currentPassword;

    if (rejectChange) {
      throw const ApiException(
        statusCode: 400,
        message: 'InvalidCurrentPassword',
      );
    }

    profileService.username = newUsername;
    return newUsername;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnsupportedError('Not used in username-change tests.');
  }
}
