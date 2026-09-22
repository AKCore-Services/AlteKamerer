import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system preference exposes no explicit locale', () async {
    final preferences = _FakeLocalePreferences(AppLocalePreference.system);
    final controller = LocaleController(preferences);

    await controller.load();

    expect(controller.preference, AppLocalePreference.system);
    expect(controller.locale, isNull);
  });

  test('Swedish preference exposes Swedish locale', () async {
    final preferences = _FakeLocalePreferences(AppLocalePreference.swedish);
    final controller = LocaleController(preferences);

    await controller.load();

    expect(controller.locale, const Locale('sv'));
  });

  test('English preference exposes English locale', () async {
    final preferences = _FakeLocalePreferences(AppLocalePreference.english);
    final controller = LocaleController(preferences);

    await controller.load();

    expect(controller.locale, const Locale('en'));
  });

  test('changing preference persists and notifies listeners', () async {
    final preferences = _FakeLocalePreferences(AppLocalePreference.system);
    final controller = LocaleController(preferences);

    await controller.load();

    var notifications = 0;
    controller.addListener(() {
      notifications += 1;
    });

    await controller.setPreference(AppLocalePreference.english);

    expect(preferences.preference, AppLocalePreference.english);
    expect(controller.preference, AppLocalePreference.english);
    expect(controller.locale, const Locale('en'));
    expect(notifications, 1);
  });
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
