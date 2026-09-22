import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system locale preference', () async {
    final preferences = await SharedPreferences.getInstance();
    final localePreferences = SharedPreferencesLocalePreferences(preferences);

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.system,
    );
  });

  test('stores Swedish locale preference', () async {
    final preferences = await SharedPreferences.getInstance();
    final localePreferences = SharedPreferencesLocalePreferences(preferences);

    await localePreferences.setLocalePreference(AppLocalePreference.swedish);

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.swedish,
    );
  });

  test('stores English locale preference', () async {
    final preferences = await SharedPreferences.getInstance();
    final localePreferences = SharedPreferencesLocalePreferences(preferences);

    await localePreferences.setLocalePreference(AppLocalePreference.english);

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.english,
    );
  });

  test('unknown stored value falls back to system', () async {
    SharedPreferences.setMockInitialValues({'locale_preference': 'de'});

    final preferences = await SharedPreferences.getInstance();
    final localePreferences = SharedPreferencesLocalePreferences(preferences);

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.system,
    );
  });
}
