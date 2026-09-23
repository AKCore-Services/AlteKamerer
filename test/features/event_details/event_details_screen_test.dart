import 'dart:async';

import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_controller.dart';
import 'package:altekamerer/features/event_details/event_details_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading state while event is loading', (
    WidgetTester tester,
  ) async {
    final service = DeferredEventDetailsService();
    final controller = EventDetailsController(service);

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.complete(_event());
    await tester.pump();
  });

  testWidgets('shows retryable error state when event load fails', (
    WidgetTester tester,
  ) async {
    final service = FakeEventDetailsService(error: StateError('event failed'));
    final controller = EventDetailsController(service);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    expect(find.text('Kunde inte hämta aktiviteten'), findsOneWidget);
    expect(find.text('Försök igen'), findsOneWidget);

    service.error = null;
    service.event = _event();

    await tester.tap(find.text('Försök igen'));
    await tester.pump();
    await tester.pump();

    expect(controller.status, EventDetailsStatus.loaded);
  });

  testWidgets('renders event details and registration state', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(
        event: _event(
          signupState: 'Hålan',
          internalDescription: 'Ta med marschmapp.',
        ),
      ),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    expect(find.text('Kårhusrep'), findsOneWidget);
    expect(find.text('Tisdagsrep'), findsOneWidget);
    expect(find.text('15/09/2026'), findsOneWidget);
    expect(find.text('Kårhuset'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('18:30'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('Ordinarie repetition'), findsOneWidget);
    expect(find.text('Intern information'), findsOneWidget);
    expect(find.text('Ta med marschmapp.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Din status: Hålan'), findsOneWidget);
    expect(find.text('12 kommer · 3 kommer inte'), findsOneWidget);
  });

  testWidgets('shows registration action when registration is available', (
    WidgetTester tester,
  ) async {
    EventDetails? selectedEvent;

    final controller = EventDetailsController(
      FakeEventDetailsService(event: _event()),
    );

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        onRegistrationPressed: (event) {
          selectedEvent = event;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Inte anmäld'), findsOneWidget);
    expect(find.text('Anmäl dig'), findsOneWidget);

    await tester.ensureVisible(find.text('Anmäl dig'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anmäl dig'));
    await tester.pump();

    expect(selectedEvent?.id, 42);
  });

  testWidgets('shows disabled registration action without handler', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(event: _event()),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    await tester.ensureVisible(find.text('Anmäl dig'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Anmäl dig'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('registered event shows change-registration action', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(event: _event(signupState: 'Direkt')),
    );

    await tester.pumpWidget(
      _TestApp(controller: controller, onRegistrationPressed: (_) {}),
    );
    await tester.pump();

    expect(find.text('Din status: Direkt'), findsOneWidget);
    expect(find.text('Ändra anmälan'), findsOneWidget);
  });

  testWidgets('disabled event explains closed registration', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(
        event: _event(disabled: true, registrationAvailable: false),
      ),
    );

    await tester.pumpWidget(
      _TestApp(controller: controller, onRegistrationPressed: (_) {}),
    );
    await tester.pump();

    expect(
      find.text('Anmälan är stängd för den här aktiviteten.'),
      findsOneWidget,
    );
    expect(find.text('Anmäl dig'), findsNothing);
    expect(find.text('Ändra anmälan'), findsNothing);
  });

  testWidgets('passed event explains unavailable registration', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(event: _event(registrationAvailable: false)),
    );

    await tester.pumpWidget(
      _TestApp(controller: controller, onRegistrationPressed: (_) {}),
    );
    await tester.pump();

    expect(
      find.text(
        'Det går inte längre att ändra anmälan för den här aktiviteten.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Rep shows Hålan time instead of zero on-site time', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(
        event: _event(type: 'Rep', halanTime: '18:00', thereTime: '00:00'),
      ),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('18:00'), findsWidgets);
    expect(find.text('00:00'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller, this.onRegistrationPressed});

  final EventDetailsController controller;
  final ValueChanged<EventDetails>? onRegistrationPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('sv'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: EventDetailsScreen(
        eventId: 42,
        controller: controller,
        onRegistrationPressed: onRegistrationPressed,
      ),
    );
  }
}

EventDetails _event({
  String type = 'Kårhusrep',
  String? signupState,
  String internalDescription = '',
  String halanTime = '18:00',
  String thereTime = '18:30',
  bool disabled = false,
  bool registrationAvailable = true,
}) {
  return EventDetails(
    id: 42,
    type: type,
    name: 'Tisdagsrep',
    place: 'Kårhuset',
    description: 'Ordinarie repetition',
    internalDescription: internalDescription,
    date: '2026-09-15',
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '120 min',
    stand: '',
    signupState: signupState,
    coming: 12,
    notComing: 3,
    disabled: disabled,
    registrationAvailable: registrationAvailable,
    registration: EventRegistrationSelection(
      where: signupState,
      car: false,
      instrument: true,
      comment: '',
      selectedInstrument: 'Flöjt',
      availableInstruments: const ['Flöjt'],
    ),
    attendees: const [],
  );
}

class FakeEventDetailsService implements EventDetailsService {
  FakeEventDetailsService({this.event, this.error});

  EventDetails? event;
  Object? error;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    if (error != null) {
      throw error!;
    }

    return event!;
  }
}

class DeferredEventDetailsService implements EventDetailsService {
  final Completer<EventDetails> _completer = Completer<EventDetails>();

  void complete(EventDetails event) {
    _completer.complete(event);
  }

  @override
  Future<EventDetails> getEvent(int eventId) {
    return _completer.future;
  }
}
