import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_profile.dart';
import 'package:altekamerer/features/me/member_profile_api.dart';
import 'package:altekamerer/features/me/member_profile_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const actualProfile = MemberProfile(
    userName: 'realuser',
    email: 'real@example.com',
    firstName: 'Actual',
    lastName: 'Member',
    phone: '',
    instrument: 'Flöjt',
    otherInstruments: [],
    roles: [],
    posts: [],
    medal: '',
    givenMedal: '',
  );

  const actualStatistics = MemberProfileStatistics(
    totalGigs: 7,
    halan: 2,
    direct: 3,
    cantCome: 1,
    car: 0,
    instrument: 0,
    comment: 0,
  );

  test('uses real profile data when the API succeeds', () async {
    final service = MemberProfilePreviewService(
      _FakeService(profile: actualProfile),
      allowPreview: true,
    );

    final profile = await service.getProfile();

    expect(profile.userName, 'realuser');
    expect(service.profileIsPreview, isFalse);
  });

  test('uses placeholders when the test API endpoint is missing', () async {
    final service = MemberProfilePreviewService(
      _FakeService(
        profileError: const ApiException(statusCode: 404, message: 'Not found'),
      ),
      allowPreview: true,
    );

    final profile = await service.getProfile();

    expect(profile.userName, 'exempelanvandare');
    expect(service.profileIsPreview, isTrue);
  });

  test('production mode never uses placeholders', () async {
    final service = MemberProfilePreviewService(
      _FakeService(
        profileError: const ApiException(statusCode: 404, message: 'Not found'),
      ),
      allowPreview: false,
    );

    await expectLater(service.getProfile(), throwsA(isA<ApiException>()));

    expect(service.profileIsPreview, isFalse);
  });

  test('authentication failures never use placeholders', () async {
    for (final statusCode in [401, 403]) {
      final service = MemberProfilePreviewService(
        _FakeService(
          profileError: ApiException(
            statusCode: statusCode,
            message: 'Authentication rejected',
          ),
        ),
        allowPreview: true,
      );

      await expectLater(
        service.getProfile(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );

      expect(service.profileIsPreview, isFalse);
    }
  });

  test('server unavailability permits test placeholders', () async {
    for (final statusCode in [408, 502, 503, 504]) {
      final service = MemberProfilePreviewService(
        _FakeService(
          profileError: ApiException(
            statusCode: statusCode,
            message: 'Unavailable',
          ),
        ),
        allowPreview: true,
      );

      final profile = await service.getProfile();

      expect(profile.userName, 'exempelanvandare');
      expect(service.profileIsPreview, isTrue);
    }
  });

  test('unexpected server errors remain visible', () async {
    final service = MemberProfilePreviewService(
      _FakeService(
        profileError: const ApiException(
          statusCode: 500,
          message: 'Internal error',
        ),
      ),
      allowPreview: true,
    );

    await expectLater(service.getProfile(), throwsA(isA<ApiException>()));
  });

  test('invalid response data never triggers placeholders', () async {
    final service = MemberProfilePreviewService(
      _FakeService(profileError: const FormatException('Invalid JSON')),
      allowPreview: true,
    );

    await expectLater(service.getProfile(), throwsA(isA<FormatException>()));
  });

  test('statistics use real data when available', () async {
    final service = MemberProfilePreviewService(
      _FakeService(statistics: actualStatistics),
      allowPreview: true,
    );

    final statistics = await service.getStatistics();

    expect(statistics.totalGigs, 7);
    expect(service.statisticsArePreview, isFalse);
  });

  test('statistics use placeholders when unavailable in test mode', () async {
    final service = MemberProfilePreviewService(
      _FakeService(
        statisticsError: const ApiException(
          statusCode: 404,
          message: 'Not found',
        ),
      ),
      allowPreview: true,
    );

    final statistics = await service.getStatistics();

    expect(statistics.totalGigs, 20);
    expect(service.statisticsArePreview, isTrue);
  });

  test('statistics authentication failures propagate', () async {
    final service = MemberProfilePreviewService(
      _FakeService(
        statisticsError: const ApiException(
          statusCode: 401,
          message: 'Unauthorized',
        ),
      ),
      allowPreview: true,
    );

    await expectLater(service.getStatistics(), throwsA(isA<ApiException>()));

    expect(service.statisticsArePreview, isFalse);
  });
}

class _FakeService implements MemberProfileService {
  const _FakeService({
    this.profile,
    this.statistics,
    this.profileError,
    this.statisticsError,
  });

  final MemberProfile? profile;
  final MemberProfileStatistics? statistics;
  final Object? profileError;
  final Object? statisticsError;

  @override
  Future<MemberProfile> getProfile() async {
    if (profileError != null) {
      throw profileError!;
    }

    return profile!;
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    if (statisticsError != null) {
      throw statisticsError!;
    }

    return statistics!;
  }
}
