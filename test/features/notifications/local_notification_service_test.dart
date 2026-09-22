import 'package:altekamerer/features/notifications/local_notification_service.dart';
import 'package:altekamerer/features/notifications/notification_navigation_controller.dart';
import 'package:altekamerer/features/notifications/notification_plan.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Swedish notification text for Swedish preference', () async {
    final service = await _createService(
      AppLocalePreference.swedish,
      systemLocale: const Locale('en'),
    );

    expect(service.channelName, 'Aktivitetspåminnelser');
    expect(
      service.channelDescription,
      'Påminnelser inför aktiviteter i AlteKamerer',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(hours: 1))),
      'Börjar om 1 timme',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(hours: 5))),
      'Börjar om 5 timmar',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(minutes: 30))),
      'Börjar om 30 minuter',
    );
  });

  test('uses English notification text for English preference', () async {
    final service = await _createService(
      AppLocalePreference.english,
      systemLocale: const Locale('sv'),
    );

    expect(service.channelName, 'Activity reminders');
    expect(
      service.channelDescription,
      'Reminders for activities in AlteKamerer',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(hours: 1))),
      'Starts in 1 hour',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(hours: 5))),
      'Starts in 5 hours',
    );
    expect(
      service.bodyForPlan(_plan(const Duration(minutes: 30))),
      'Starts in 30 minutes',
    );
  });

  test('system preference follows Swedish system locale', () async {
    final service = await _createService(
      AppLocalePreference.system,
      systemLocale: const Locale('sv'),
    );

    expect(service.channelName, 'Aktivitetspåminnelser');
    expect(
      service.bodyForPlan(_plan(const Duration(minutes: 30))),
      'Börjar om 30 minuter',
    );
  });

  test(
    'system preference falls back to English for unsupported locale',
    () async {
      final service = await _createService(
        AppLocalePreference.system,
        systemLocale: const Locale('de'),
      );

      expect(service.channelName, 'Activity reminders');
      expect(
        service.bodyForPlan(_plan(const Duration(minutes: 30))),
        'Starts in 30 minutes',
      );
    },
  );
}

Future<LocalNotificationService> _createService(
  AppLocalePreference preference, {
  required Locale systemLocale,
}) async {
  final controller = LocaleController(_FakeLocalePreferences(preference));
  await controller.load();

  return LocalNotificationService(
    FlutterLocalNotificationsPlugin(),
    NotificationNavigationController(),
    controller,
    systemLocale: () => systemLocale,
  );
}

NotificationPlan _plan(Duration offset) {
  return NotificationPlan(
    eventId: 42,
    eventName: 'Tisdagsrep',
    eventTime: DateTime.utc(2026, 9, 22, 18),
    reminderOffset: offset,
    scheduledTime: DateTime.utc(2026, 9, 22, 17),
  );
}

class _FakeLocalePreferences implements LocalePreferences {
  _FakeLocalePreferences(this.preference);

  AppLocalePreference preference;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return preference;
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    this.preference = preference;
  }
}
