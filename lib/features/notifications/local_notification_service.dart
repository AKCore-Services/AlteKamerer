import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../settings/locale_controller.dart';
import '../settings/locale_preferences.dart';
import 'notification_event_payload.dart';
import 'notification_navigation_controller.dart';
import 'notification_plan.dart';

abstract interface class LocalNotificationScheduler {
  Future<void> reconcile(List<NotificationPlan> plans);

  Future<void> clear();
}

class LocalNotificationService implements LocalNotificationScheduler {
  LocalNotificationService(
    this._plugin,
    this._navigationController,
    this._localeController, {
    Locale Function()? systemLocale,
  }) : _systemLocale =
           systemLocale ??
           (() => WidgetsBinding.instance.platformDispatcher.locale);

  static const _channelId = 'event-reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationNavigationController _navigationController;
  final LocaleController _localeController;
  final Locale Function() _systemLocale;

  late final tz.Location _stockholm;
  bool _permissionRequested = false;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    _stockholm = tz.getLocation('Europe/Stockholm');

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );

    await _ensureNotificationChannel();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleResponse(launchDetails?.notificationResponse);
    }
  }

  @override
  Future<void> reconcile(List<NotificationPlan> plans) async {
    await _ensureNotificationChannel();

    if (plans.isNotEmpty && !_permissionRequested) {
      _permissionRequested = true;

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.requestNotificationsPermission();
    }

    await _plugin.cancelAll();

    for (final plan in plans) {
      await _schedule(plan);
    }
  }

  @override
  Future<void> clear() async {
    await _plugin.cancelAll();
  }

  Future<void> _ensureNotificationChannel() async {
    final l10n = _localizations();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        l10n.notificationChannelName,
        description: l10n.notificationChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _schedule(NotificationPlan plan) async {
    final l10n = _localizations();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(plan),
      title: plan.eventName,
      body: _bodyFor(plan),
      scheduledDate: tz.TZDateTime.from(plan.scheduledTime, _stockholm),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationEventPayload.encode(plan.eventId),
    );
  }

  int _notificationId(NotificationPlan plan) {
    final minutes = plan.reminderOffset.inMinutes;

    return ((plan.eventId * 100000) + minutes) & 0x7fffffff;
  }

  String _bodyFor(NotificationPlan plan) {
    final l10n = _localizations();
    final minutes = plan.reminderOffset.inMinutes;

    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;

      if (hours == 1) {
        return l10n.notificationStartsInOneHour;
      }

      return l10n.notificationStartsInHours(hours);
    }

    return l10n.notificationStartsInMinutes(minutes);
  }

  AppLocalizations _localizations() {
    return lookupAppLocalizations(_resolvedLocale());
  }

  Locale _resolvedLocale() {
    return switch (_localeController.preference) {
      AppLocalePreference.swedish => const Locale('sv'),
      AppLocalePreference.english => const Locale('en'),
      AppLocalePreference.system =>
        _systemLocale().languageCode == 'sv'
            ? const Locale('sv')
            : const Locale('en'),
    };
  }

  @visibleForTesting
  String bodyForPlan(NotificationPlan plan) {
    return _bodyFor(plan);
  }

  @visibleForTesting
  String get channelName {
    return _localizations().notificationChannelName;
  }

  @visibleForTesting
  String get channelDescription {
    return _localizations().notificationChannelDescription;
  }

  void _handleResponse(NotificationResponse? response) {
    final eventId = NotificationEventPayload.tryParse(response?.payload);

    if (eventId != null) {
      _navigationController.openEvent(eventId);
    }
  }
}
