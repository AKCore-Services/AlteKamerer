import 'dart:async';

import 'package:altekamerer/features/me/member_profile.dart';
import 'package:altekamerer/features/me/member_profile_api.dart';
import 'package:altekamerer/features/me/member_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = MemberProfile.fromJson({
    'userName': 'testmember',
    'email': 'test@example.com',
    'firstName': 'Test',
    'lastName': 'Testsson',
    'phone': '',
    'instrument': 'Trumpet',
    'otherInstruments': <String>[],
    'roles': <String>['Medlem'],
    'posts': <String>[],
    'medal': '',
    'givenMedal': '',
  });

  const statistics = MemberProfileStatistics(
    totalGigs: 10,
    halan: 4,
    direct: 3,
    cantCome: 2,
    car: 1,
    instrument: 1,
    comment: 0,
  );

  const updateRequest = MemberProfileUpdateRequest(
    firstName: 'Updated',
    lastName: 'Testsson',
    email: 'updated@example.com',
    phone: '0701234567',
    instrument: 'Trumpet',
    otherInstruments: [],
  );

  final updatedProfile = MemberProfile(
    userName: profile.userName,
    email: 'updated@example.com',
    firstName: 'Updated',
    lastName: profile.lastName,
    phone: '0701234567',
    instrument: profile.instrument,
    otherInstruments: profile.otherInstruments,
    roles: profile.roles,
    posts: profile.posts,
    medal: profile.medal,
    givenMedal: profile.givenMedal,
  );

  test('loads the authenticated profile', () async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    expect(controller.status, MemberProfileStatus.idle);

    await controller.load();

    expect(controller.status, MemberProfileStatus.loaded);
    expect(controller.profile?.displayName, 'Test Testsson');
    expect(controller.statistics, isNull);
    expect(controller.error, isNull);
  });

  test('loads statistics separately', () async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await controller.load();
    await controller.loadStatistics();

    expect(controller.statistics?.totalGigs, 10);
    expect(controller.profile?.userName, 'testmember');
  });

  test('handles profile loading failures', () async {
    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        profileError: StateError('Network unavailable'),
      ),
    );

    await controller.load();

    expect(controller.status, MemberProfileStatus.error);
    expect(controller.error, isA<StateError>());
  });

  test('statistics failure does not hide the profile', () async {
    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        statisticsError: StateError('Statistics unavailable'),
      ),
    );

    await controller.load();
    await controller.loadStatistics();

    expect(controller.status, MemberProfileStatus.loaded);
    expect(controller.profile, isNotNull);
    expect(controller.statistics, isNull);
    expect(controller.error, isA<StateError>());
  });

  test('clears all session-scoped profile information', () async {
    final controller = MemberProfileController(
      _FakeProfileService(profile: profile, statistics: statistics),
    );

    await controller.load();
    await controller.loadStatistics();

    controller.clear();

    expect(controller.status, MemberProfileStatus.idle);
    expect(controller.profile, isNull);
    expect(controller.statistics, isNull);
    expect(controller.error, isNull);
  });

  test('ignores profile responses completed after session cleanup', () async {
    final pending = Completer<MemberProfile>();
    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        profileFuture: pending.future,
      ),
    );

    final loading = controller.load();

    controller.clear();
    pending.complete(profile);

    await loading;

    expect(controller.status, MemberProfileStatus.idle);
    expect(controller.profile, isNull);
  });

  test(
    'ignores statistics responses completed after session cleanup',
    () async {
      final pending = Completer<MemberProfileStatistics>();
      final controller = MemberProfileController(
        _FakeProfileService(
          profile: profile,
          statistics: statistics,
          statisticsFuture: pending.future,
        ),
      );

      await controller.load();

      final loading = controller.loadStatistics();

      controller.clear();
      pending.complete(statistics);

      await loading;

      expect(controller.statistics, isNull);
      expect(controller.profile, isNull);
    },
  );

  test('saves and displays the server-confirmed profile', () async {
    final pending = Completer<MemberProfile>();
    MemberProfileUpdateRequest? submitted;

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        updateFuture: pending.future,
        onUpdate: (request) => submitted = request,
      ),
    );

    await controller.load();

    final saving = controller.saveProfile(updateRequest);

    expect(controller.isSaving, isTrue);
    expect(controller.profile, same(profile));
    expect(controller.saveError, isNull);
    expect(submitted, same(updateRequest));

    pending.complete(updatedProfile);

    expect(await saving, isTrue);
    expect(controller.isSaving, isFalse);
    expect(controller.profile, same(updatedProfile));
    expect(controller.status, MemberProfileStatus.loaded);
    expect(controller.saveError, isNull);
  });

  test('failed saves preserve the existing profile', () async {
    final failure = StateError('Update rejected');

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        updateError: failure,
      ),
    );

    await controller.load();

    expect(await controller.saveProfile(updateRequest), isFalse);
    expect(controller.profile, same(profile));
    expect(controller.status, MemberProfileStatus.loaded);
    expect(controller.isSaving, isFalse);
    expect(controller.saveError, same(failure));
    expect(controller.error, isNull);
  });

  test('prevents duplicate profile submissions', () async {
    final pending = Completer<MemberProfile>();
    var updateCalls = 0;

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        updateFuture: pending.future,
        onUpdate: (_) {
          updateCalls++;
        },
      ),
    );

    await controller.load();

    final firstSave = controller.saveProfile(updateRequest);

    expect(await controller.saveProfile(updateRequest), isFalse);
    expect(updateCalls, 1);

    pending.complete(updatedProfile);

    expect(await firstSave, isTrue);
    expect(updateCalls, 1);
  });

  test('cannot save before a profile has loaded', () async {
    var updateCalls = 0;

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        onUpdate: (_) {
          updateCalls++;
        },
      ),
    );

    expect(await controller.saveProfile(updateRequest), isFalse);
    expect(updateCalls, 0);
    expect(controller.profile, isNull);
  });

  test('ignores a saved profile returned after logout', () async {
    final pending = Completer<MemberProfile>();

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        updateFuture: pending.future,
      ),
    );

    await controller.load();

    final saving = controller.saveProfile(updateRequest);

    controller.clear();
    pending.complete(updatedProfile);

    expect(await saving, isFalse);
    expect(controller.status, MemberProfileStatus.idle);
    expect(controller.profile, isNull);
    expect(controller.isSaving, isFalse);
    expect(controller.saveError, isNull);
  });

  test('older saves cannot overwrite a newer profile load', () async {
    final pending = Completer<MemberProfile>();

    final controller = MemberProfileController(
      _FakeProfileService(
        profile: profile,
        statistics: statistics,
        updateFuture: pending.future,
      ),
    );

    await controller.load();

    final saving = controller.saveProfile(updateRequest);

    await controller.load();

    pending.complete(updatedProfile);

    expect(await saving, isFalse);
    expect(controller.profile, same(profile));
    expect(controller.status, MemberProfileStatus.loaded);
    expect(controller.isSaving, isFalse);
  });
}

class _FakeProfileService implements MemberProfileService {
  @override
  Future<MemberProfile> updateProfile(
    MemberProfileUpdateRequest request,
  ) async {
    onUpdate?.call(request);

    if (updateError != null) {
      throw updateError!;
    }

    return updateFuture ?? profile;
  }

  const _FakeProfileService({
    required this.profile,
    required this.statistics,
    this.profileError,
    this.statisticsError,
    this.profileFuture,
    this.statisticsFuture,
    this.updateError,
    this.updateFuture,
    this.onUpdate,
  });

  final MemberProfile profile;
  final MemberProfileStatistics statistics;
  final Object? profileError;
  final Object? statisticsError;
  final Future<MemberProfile>? profileFuture;
  final Future<MemberProfileStatistics>? statisticsFuture;
  final Object? updateError;
  final Future<MemberProfile>? updateFuture;
  final void Function(MemberProfileUpdateRequest)? onUpdate;

  @override
  Future<MemberProfile> getProfile() async {
    if (profileError != null) {
      throw profileError!;
    }

    return profileFuture ?? profile;
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    if (statisticsError != null) {
      throw statisticsError!;
    }

    return statisticsFuture ?? statistics;
  }
}
