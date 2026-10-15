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
}

class _FakeProfileService implements MemberProfileService {
  const _FakeProfileService({
    required this.profile,
    required this.statistics,
    this.profileError,
    this.statisticsError,
    this.profileFuture,
    this.statisticsFuture,
  });

  final MemberProfile profile;
  final MemberProfileStatistics statistics;
  final Object? profileError;
  final Object? statisticsError;
  final Future<MemberProfile>? profileFuture;
  final Future<MemberProfileStatistics>? statisticsFuture;

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
