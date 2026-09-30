import 'package:altekamerer/core/diagnostics/diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records and restores diagnostic errors', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DiagnosticsService(
      preferences,
      now: () => DateTime.utc(2026, 9, 29, 11, 21, 4),
    );

    await service.recordError(
      subsystem: 'Calendar',
      message: 'Calendar refresh failed',
      error: const FormatException('Expected calendar events array.'),
    );

    final entries = await service.readEntries();

    expect(entries, hasLength(1));
    expect(entries.single.subsystem, 'Calendar');
    expect(entries.single.message, 'Calendar refresh failed');
    expect(entries.single.details, contains('Expected calendar events array.'));
    expect(entries.single.timestamp, DateTime.utc(2026, 9, 29, 11, 21, 4));
  });

  test('retains only the newest configured number of entries', () async {
    final preferences = await SharedPreferences.getInstance();
    var minute = 0;
    final service = DiagnosticsService(
      preferences,
      maxEntries: 3,
      now: () => DateTime.utc(2026, 9, 29, 11, minute++),
    );

    for (var index = 0; index < 5; index++) {
      await service.recordError(subsystem: 'Test', message: 'Failure $index');
    }

    final entries = await service.readEntries();

    expect(entries.map((entry) => entry.message), [
      'Failure 2',
      'Failure 3',
      'Failure 4',
    ]);
  });

  test('clear removes stored diagnostics', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DiagnosticsService(preferences);

    await service.recordError(
      subsystem: 'Notifications',
      message: 'Notification synchronization failed',
    );

    await service.clear();

    expect(await service.readEntries(), isEmpty);
  });

  test('sanitizes credentials and tokens before storage', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DiagnosticsService(preferences);

    await service.recordError(
      subsystem: 'Authentication',
      message: 'Session refresh failed',
      error: Exception(
        'password=hunter2 '
        'accessToken=access-secret '
        'refresh_token=refresh-secret '
        'sessionId=session-secret '
        'deviceToken=device-secret '
        'Authorization: Bearer bearer-secret',
      ),
    );

    final details = (await service.readEntries()).single.details!;

    expect(details, isNot(contains('hunter2')));
    expect(details, isNot(contains('access-secret')));
    expect(details, isNot(contains('refresh-secret')));
    expect(details, isNot(contains('session-secret')));
    expect(details, isNot(contains('device-secret')));
    expect(details, isNot(contains('bearer-secret')));
    expect(details, contains('[REDACTED]'));
  });

  test('ignores malformed stored diagnostics', () async {
    SharedPreferences.setMockInitialValues({'diagnostic_entries': 'not json'});
    final preferences = await SharedPreferences.getInstance();
    final service = DiagnosticsService(preferences);

    expect(await service.readEntries(), isEmpty);
  });

  test('builds a human-readable diagnostic report', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DiagnosticsService(
      preferences,
      now: () => DateTime(2026, 9, 29, 11, 24, 31),
    );

    await service.recordError(
      subsystem: 'Calendar',
      message: 'Calendar refresh failed',
      error: Exception('HTTP 500 GET /api/v1/calendar'),
    );

    final report = service.buildReport(
      version: '1.1.1',
      buildNumber: '3',
      platform: 'Android 16',
      apiServer: 'https://www.altekamereren.org',
      entries: await service.readEntries(),
    );

    expect(report, contains('AlteKamerer diagnostics'));
    expect(report, contains('Version: 1.1.1'));
    expect(report, contains('Build: 3'));
    expect(report, contains('Platform: Android 16'));
    expect(report, contains('API server: https://www.altekamereren.org'));
    expect(report, contains('ERROR Calendar'));
    expect(report, contains('Calendar refresh failed'));
    expect(report, contains('HTTP 500 GET /api/v1/calendar'));
  });
}
