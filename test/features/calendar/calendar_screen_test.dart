import 'dart:async';

import 'package:altekamerer/core/theme/app_theme.dart';
import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:altekamerer/features/calendar/calendar_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading state while calendar is loading', (
    WidgetTester tester,
  ) async {
    final service = DeferredCalendarService();
    final controller = CalendarController(service);

    final load = controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.complete(const []);
    await load;
  });

  testWidgets('shows empty state when calendar has no events', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
    );

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Inga kommande aktiviteter'), findsOneWidget);
  });

  testWidgets('shows retryable error state when calendar fails', (
    WidgetTester tester,
  ) async {
    final service = FakeCalendarService(error: StateError('calendar failed'));
    final controller = CalendarController(service);

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Kunde inte hämta kalendern'), findsOneWidget);
    expect(find.text('Försök igen'), findsOneWidget);

    service.error = null;
    service.events = const [];

    await tester.tap(find.text('Försök igen'));
    await tester.pump();
    await tester.pump();

    expect(controller.status, CalendarStatus.loaded);
  });

  testWidgets('renders compact calendar event information', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(type: 'Spelning', place: 'Kungmarken', signupState: 'Direkt'),
        ],
      ),
    );

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('15/09'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
    expect(find.text('Spelning'), findsOneWidget);
    expect(find.text('Kungmarken'), findsOneWidget);
    expect(find.byTooltip('Anmäld: Direkt'), findsOneWidget);
  });

  testWidgets('large text uses adaptive calendar event layout', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(type: 'Spelning', place: 'Kungmarken', signupState: 'Direkt'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Datum'), findsNothing);
    expect(find.text('Datum: 15/09', findRichText: true), findsOneWidget);
    expect(find.text('Tid: 18:30', findRichText: true), findsOneWidget);
    expect(find.text('Typ: Spelning', findRichText: true), findsOneWidget);
    expect(find.text('Plats: Kungmarken', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hålan registration shows Hålan time and attending indicator', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event(signupState: 'Hålan')]),
    );

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('18:00'), findsOneWidget);
    expect(find.byTooltip('Anmäld: Hålan'), findsOneWidget);
  });

  testWidgets('Kan inte komma shows registered non-attending indicator', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event(signupState: 'Kan inte komma')]),
    );

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('18:30'), findsOneWidget);
    expect(find.byTooltip('Anmäld: Kan inte komma'), findsOneWidget);
  });

  testWidgets('unregistered event shows unregistered indicator', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
    );

    await controller.load();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byTooltip('Inte anmäld'), findsOneWidget);
  });

  testWidgets('shows calendar view selector', (WidgetTester tester) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Kommande'), findsOneWidget);
    expect(find.text('Idag'), findsOneWidget);
    expect(find.text('Vecka'), findsOneWidget);
    expect(find.text('Månad'), findsOneWidget);
  });

  testWidgets('today view renders only today events', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, place: 'Today place', date: '2026-09-15'),
          _event(id: 2, place: 'Tomorrow place', date: '2026-09-16'),
        ],
      ),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.text('Idag'));
    await tester.pump();

    expect(find.text('Today place'), findsOneWidget);
    expect(find.text('Tomorrow place'), findsNothing);
  });

  testWidgets('calendar renders on a narrow phone viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('calendar-filters-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-search-field')), findsNothing);
    expect(find.text('Kommande'), findsOneWidget);
    expect(find.text('Idag'), findsOneWidget);
    expect(find.text('Kårhuset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty selected view keeps controls visible', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event(date: '2026-09-16')]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.text('Idag'));
    await tester.pump();

    expect(find.text('Inga aktiviteter i den här vyn'), findsOneWidget);
    expect(find.text('Kommande'), findsOneWidget);
    expect(find.text('Idag'), findsOneWidget);
  });

  testWidgets('week view shows period navigation', (WidgetTester tester) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.text('Vecka'));
    await tester.pump();

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-current-period-button')),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('calendar-current-period-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('calendar-current-period-button')),
    );
    await tester.pump();

    expect(controller.isCurrentPeriod, isTrue);
    expect(
      find.byKey(const ValueKey('calendar-current-period-button')),
      findsNothing,
    );
  });

  testWidgets('month view navigation changes visible month', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, place: 'September place', date: '2026-09-30'),
          _event(id: 2, place: 'October place', date: '2026-10-01'),
        ],
      ),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.text('Månad'));
    await tester.pump();

    expect(find.text('September place'), findsOneWidget);
    expect(find.text('October place'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(find.text('September place'), findsNothing);
    expect(find.text('October place'), findsOneWidget);
  });

  testWidgets('shows compact filter button and opens filter sheet', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, type: 'Rep'),
          _event(id: 2, type: 'Spelning'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(
      find.byKey(const ValueKey('calendar-filters-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-activity-filter')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('calendar-status-filter')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendar-activity-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-status-filter')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-search-field')), findsOneWidget);
    expect(find.text('Aktivitet'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Återställ filter'), findsOneWidget);
  });

  testWidgets('filter sheet is localized in English', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event(type: 'Rep')]),
    );

    await controller.load();

    await tester.pumpWidget(
      _TestApp(controller: controller, locale: const Locale('en')),
    );

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-status-filter')));
    await tester.pumpAndSettle();

    expect(find.text('All statuses'), findsWidgets);
    expect(find.text('Coming'), findsOneWidget);
    expect(find.text('Not registered'), findsOneWidget);
    expect(find.text('Not coming'), findsOneWidget);
  });

  testWidgets('activity filter uses exact existing event types', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, type: 'Rep', place: 'Orchestra place'),
          _event(id: 2, type: 'Kårhusrep', place: 'Kårhus place'),
          _event(id: 3, type: 'Spelning', place: 'Gig place'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-activity-filter')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kårhusrep').last);
    await tester.pumpAndSettle();

    expect(controller.eventTypeFilter, 'Kårhusrep');
    expect(find.text('Orchestra place'), findsNothing);
    expect(find.text('Kårhus place'), findsOneWidget);
    expect(find.text('Gig place'), findsNothing);
  });

  testWidgets('status filter groups Hålan and Direkt as coming', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, place: 'Hålan place', signupState: 'Hålan'),
          _event(id: 2, place: 'Direkt place', signupState: 'Direkt'),
          _event(id: 3, place: 'Cannot place', signupState: 'Kan inte komma'),
          _event(id: 4, place: 'Unregistered place'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-status-filter')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kommer').last);
    await tester.pumpAndSettle();

    expect(controller.registrationFilter, CalendarRegistrationFilter.coming);
    expect(find.text('Hålan place'), findsOneWidget);
    expect(find.text('Direkt place'), findsOneWidget);
    expect(find.text('Cannot place'), findsNothing);
    expect(find.text('Unregistered place'), findsNothing);
  });

  testWidgets('activity and status filters compose', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(
            id: 1,
            type: 'Rep',
            place: 'Matching place',
            signupState: 'Direkt',
          ),
          _event(
            id: 2,
            type: 'Rep',
            place: 'Wrong status place',
            signupState: 'Kan inte komma',
          ),
          _event(
            id: 3,
            type: 'Spelning',
            place: 'Wrong activity place',
            signupState: 'Direkt',
          ),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-activity-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orkesterrep').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kommer').last);
    await tester.pumpAndSettle();

    expect(find.text('Matching place'), findsOneWidget);
    expect(find.text('Wrong status place'), findsNothing);
    expect(find.text('Wrong activity place'), findsNothing);
  });

  testWidgets('search composes with activity and status filters', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(
            id: 1,
            type: 'Rep',
            name: 'Monday orchestra',
            place: 'Matching place',
            signupState: 'Direkt',
          ),
          _event(
            id: 2,
            type: 'Rep',
            name: 'Tuesday orchestra',
            place: 'Wrong search place',
            signupState: 'Direkt',
          ),
          _event(
            id: 3,
            type: 'Rep',
            name: 'Monday rehearsal',
            place: 'Wrong status place',
            signupState: 'Kan inte komma',
          ),
          _event(
            id: 4,
            type: 'Spelning',
            name: 'Monday performance',
            place: 'Wrong activity place',
            signupState: 'Direkt',
          ),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byKey(const ValueKey('calendar-search-field')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('calendar-search-field')),
      'Monday',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('calendar-activity-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orkesterrep').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kommer').last);
    await tester.pumpAndSettle();

    expect(find.text('Matching place'), findsOneWidget);
    expect(find.text('Wrong search place'), findsNothing);
    expect(find.text('Wrong status place'), findsNothing);
    expect(find.text('Wrong activity place'), findsNothing);
  });

  testWidgets('reset filters restores all activities and statuses', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, type: 'Rep', place: 'Rep place', signupState: 'Direkt'),
          _event(
            id: 2,
            type: 'Spelning',
            place: 'Gig place',
            signupState: 'Kan inte komma',
          ),
        ],
      ),
    );

    await controller.load();
    controller.setEventTypeFilter('Rep');
    controller.setRegistrationFilter(CalendarRegistrationFilter.coming);

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Rep place'), findsOneWidget);
    expect(find.text('Gig place'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-reset-filters')));
    await tester.pumpAndSettle();

    expect(controller.eventTypeFilter, isNull);
    expect(controller.registrationFilter, CalendarRegistrationFilter.all);
    expect(find.text('Rep place'), findsOneWidget);
    expect(find.text('Gig place'), findsOneWidget);
  });

  testWidgets('shows localized calendar search field', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byKey(const ValueKey('calendar-search-field')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    final searchField = find.byKey(const ValueKey('calendar-search-field'));

    expect(searchField, findsOneWidget);
    expect(find.text('Sök i kalendern'), findsOneWidget);
    expect(find.text('Namn, plats, beskrivning eller typ'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('calendar search changes visible events', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, name: 'Höstkonsert', place: 'Stora salen'),
          _event(id: 2, name: 'Veckorep', place: 'Kårhuset'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Stora salen'), findsOneWidget);
    expect(find.text('Kårhuset'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('calendar-search-field')),
      'höst',
    );
    await tester.pump();

    expect(controller.searchQuery, 'höst');
    expect(find.text('Stora salen'), findsOneWidget);
    expect(find.text('Kårhuset'), findsNothing);
  });

  testWidgets('clearing calendar search restores visible events', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, name: 'Concert', place: 'Concert place'),
          _event(id: 2, name: 'Rehearsal', place: 'Rehearsal place'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-filters-button')));
    await tester.pumpAndSettle();

    final searchField = find.byKey(const ValueKey('calendar-search-field'));

    await tester.enterText(searchField, 'Concert');
    await tester.pump();

    expect(find.text('Concert place'), findsOneWidget);
    expect(find.text('Rehearsal place'), findsNothing);

    await tester.enterText(searchField, '');
    await tester.pump();

    expect(find.text('Concert place'), findsOneWidget);
    expect(find.text('Rehearsal place'), findsOneWidget);
  });

  testWidgets('calendar display settings update the running calendar', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
    );
    final displayController = _createDisplayController();

    await controller.load();
    await displayController.load();

    await tester.pumpWidget(
      _TestApp(controller: controller, displayController: displayController),
    );

    expect(find.text('15/09'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);

    await displayController.setShowWeekday(true);
    await displayController.setTimeFormat(CalendarTimeFormat.twelveHour);
    await tester.pump();

    expect(find.text('tis 15/09'), findsOneWidget);
    expect(find.text('6:30 em'), findsOneWidget);
    expect(find.text('Datum'), findsOneWidget);
    expect(find.text('Tid'), findsOneWidget);
    expect(find.text('Datum: tis 15/09', findRichText: true), findsNothing);
    expect(find.text('Tid: 6:30 em', findRichText: true), findsNothing);
  });

  testWidgets('written date format reaches the calendar row', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
    );
    final displayController = _createDisplayController(
      const CalendarDisplaySettings(
        dateFormat: CalendarDateFormat.written,
        showWeekday: true,
      ),
    );

    await controller.load();
    await displayController.load();

    await tester.pumpWidget(
      _TestApp(controller: controller, displayController: displayController),
    );

    expect(find.text('tis 15 sep. 2026'), findsOneWidget);
    expect(find.text('Datum'), findsOneWidget);
    expect(
      find.text('Datum: tis 15 sep. 2026', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('tapping event reports selected calendar event', (
    WidgetTester tester,
  ) async {
    final event = _event();
    final controller = CalendarController(FakeCalendarService(events: [event]));

    await controller.load();

    CalendarEvent? selectedEvent;

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        onOpenEvent: (event) {
          selectedEvent = event;
        },
      ),
    );

    await tester.tap(find.text('Kårhusrep'));
    await tester.pump();

    expect(selectedEvent, same(event));
  });
}

class _TestApp extends StatelessWidget {
  _TestApp({
    required this.controller,
    CalendarDisplayController? displayController,
    this.onOpenEvent,
    this.locale = const Locale('sv'),
  }) : displayController = displayController ?? _createDisplayController();

  final CalendarController controller;
  final CalendarDisplayController displayController;
  final ValueChanged<CalendarEvent>? onOpenEvent;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CalendarScreen(
          controller: controller,
          displayController: displayController,
          onOpenEvent: onOpenEvent ?? (_) {},
          onRefresh: controller.load,
        ),
      ),
    );
  }
}

CalendarDisplayController _createDisplayController([
  CalendarDisplaySettings settings = const CalendarDisplaySettings(),
]) {
  return CalendarDisplayController(_FakeCalendarDisplayPreferences(settings));
}

class _FakeCalendarDisplayPreferences implements CalendarDisplayPreferences {
  _FakeCalendarDisplayPreferences(this.settings);

  CalendarDisplaySettings settings;

  @override
  Future<CalendarDisplaySettings> getSettings() async => settings;

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    this.settings = settings;
  }
}

CalendarEvent _event({
  int id = 1,
  String type = 'Kårhusrep',
  String name = 'Event',
  String place = 'Kårhuset',
  String description = '',
  String? signupState,
  String date = '2026-09-15',
}) {
  return CalendarEvent(
    id: id,
    type: type,
    name: name,
    place: place,
    description: description,
    internalDescription: '',
    date: date,
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '',
    stand: '',
    signupState: signupState,
    coming: 0,
    notComing: 0,
    disabled: false,
  );
}

class FakeCalendarService implements CalendarService {
  FakeCalendarService({this.events = const [], this.error});

  List<CalendarEvent> events;
  Object? error;

  @override
  Future<List<CalendarEvent>> getCalendar() async {
    if (error != null) {
      throw error!;
    }

    return events;
  }
}

class DeferredCalendarService implements CalendarService {
  final Completer<List<CalendarEvent>> _completer =
      Completer<List<CalendarEvent>>();

  void complete(List<CalendarEvent> events) {
    _completer.complete(events);
  }

  @override
  Future<List<CalendarEvent>> getCalendar() {
    return _completer.future;
  }
}
