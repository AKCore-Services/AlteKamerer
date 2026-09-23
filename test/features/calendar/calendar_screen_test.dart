import 'dart:async';

import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
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
    expect(find.text('Idag'), findsWidgets);
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

  testWidgets('shows semantic and event type calendar filters', (
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
      find.byKey(const ValueKey('calendar-semantic-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-event-type-filter')),
      findsOneWidget,
    );

    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Aktivitetstyp'), findsOneWidget);
  });

  testWidgets('semantic rehearsal filter changes visible events', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, type: 'Rep', place: 'Rep place'),
          _event(id: 2, type: 'Spelning', place: 'Gig place'),
        ],
      ),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-semantic-filter')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repetitioner').last);
    await tester.pumpAndSettle();

    expect(find.text('Rep place'), findsOneWidget);
    expect(find.text('Gig place'), findsNothing);
  });

  testWidgets('exact event type filter composes with semantic filter', (
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

    await tester.tap(find.byKey(const ValueKey('calendar-semantic-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repetitioner').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('calendar-event-type-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kårhusrep').last);
    await tester.pumpAndSettle();

    expect(find.text('Orchestra place'), findsNothing);
    expect(find.text('Kårhus place'), findsOneWidget);
    expect(find.text('Gig place'), findsNothing);
  });

  testWidgets('relevant filter follows member context', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(
        events: [
          _event(id: 1, type: 'Rep', place: 'Orchestra place'),
          _event(id: 2, type: 'Balettrep', place: 'Ballet place'),
        ],
      ),
    );

    await controller.load();
    controller.setMemberContext(isBallet: true);

    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-semantic-filter')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relevanta').last);
    await tester.pumpAndSettle();

    expect(find.text('Orchestra place'), findsNothing);
    expect(find.text('Ballet place'), findsOneWidget);
  });

  testWidgets('relevant filter is disabled until member context is available', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event(id: 1, type: 'Rep')]),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('calendar-semantic-filter')));
    await tester.pumpAndSettle();

    final relevantItem = tester.widget<DropdownMenuItem<CalendarFilter>>(
      find
          .ancestor(
            of: find.text('Relevanta').last,
            matching: find.byType(DropdownMenuItem<CalendarFilter>),
          )
          .first,
    );

    expect(relevantItem.enabled, isFalse);
  });

  testWidgets('shows localized calendar search field', (
    WidgetTester tester,
  ) async {
    final controller = CalendarController(
      FakeCalendarService(events: [_event()]),
    );

    await controller.load();
    await tester.pumpWidget(_TestApp(controller: controller));

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
  const _TestApp({required this.controller, this.onOpenEvent});

  final CalendarController controller;
  final ValueChanged<CalendarEvent>? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('sv'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CalendarScreen(
          controller: controller,
          onOpenEvent: onOpenEvent ?? (_) {},
          onRefresh: controller.load,
        ),
      ),
    );
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
