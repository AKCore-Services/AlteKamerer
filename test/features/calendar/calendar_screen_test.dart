import 'dart:async';

import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/calendar/calendar_screen.dart';
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
      home: Scaffold(
        body: CalendarScreen(
          controller: controller,
          onOpenEvent: onOpenEvent ?? (_) {},
        ),
      ),
    );
  }
}

CalendarEvent _event({
  String type = 'Kårhusrep',
  String place = 'Kårhuset',
  String? signupState,
}) {
  return CalendarEvent(
    id: 1,
    type: type,
    name: 'Event',
    place: place,
    description: '',
    internalDescription: '',
    date: '2026-09-15',
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
