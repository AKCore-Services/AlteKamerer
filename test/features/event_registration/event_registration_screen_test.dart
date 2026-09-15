import 'dart:async';

import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:altekamerer/features/event_registration/event_registration_controller.dart';
import 'package:altekamerer/features/event_registration/event_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows existing registration values', (
    WidgetTester tester,
  ) async {
    final controller = EventRegistrationController(
      _FakeRegistrationService(),
      _event(
        where: 'Direkt',
        car: true,
        instrument: false,
        comment: 'Kommer direkt',
        selectedInstrument: 'Piccolo',
      ),
    );

    await tester.pumpWidget(_TestApp(controller));

    expect(find.text('Direkt'), findsOneWidget);
    expect(find.text('Kommer direkt'), findsOneWidget);
    expect(find.text('Piccolo'), findsOneWidget);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();

    expect(switches[0].value, isTrue);
    expect(switches[1].value, isFalse);
  });

  testWidgets('edits fields and submits registration', (
    WidgetTester tester,
  ) async {
    final service = _FakeRegistrationService();
    final controller = EventRegistrationController(service, _event());

    await tester.pumpWidget(_TestApp(controller));

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hålan').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Har bil'));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Kommentar'),
      'Ny kommentar',
    );

    final instrumentDropdown = find
        .byType(DropdownButtonFormField<String>)
        .at(1);

    await tester.ensureVisible(instrumentDropdown);
    await tester.pumpAndSettle();

    await tester.tap(instrumentDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Piccolo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spara anmälan'));
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));

    final request = service.requests.single;

    expect(request.where, 'Hålan');
    expect(request.car, isTrue);
    expect(request.comment, 'Ny kommentar');
    expect(request.selectedInstrument, 'Piccolo');
  });

  testWidgets('shows validation error when where is missing', (
    WidgetTester tester,
  ) async {
    final controller = EventRegistrationController(
      _FakeRegistrationService(),
      _event(),
    );

    await tester.pumpWidget(_TestApp(controller));

    await tester.tap(find.text('Spara anmälan'));
    await tester.pump();

    expect(find.text('Du måste välja hur du kommer.'), findsOneWidget);
  });

  testWidgets('shows backend error without closing screen', (
    WidgetTester tester,
  ) async {
    final controller = EventRegistrationController(
      _FakeRegistrationService(
        error: const ApiException(statusCode: 400, message: 'Request failed.'),
      ),
      _event(where: 'Direkt'),
    );

    await tester.pumpWidget(_TestApp(controller));

    await tester.tap(find.text('Spara anmälan'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Anmälan kunde inte sparas. Kontrollera uppgifterna och försök igen.',
      ),
      findsOneWidget,
    );
    expect(find.byType(EventRegistrationScreen), findsOneWidget);
  });

  testWidgets('disables form and shows progress while saving', (
    WidgetTester tester,
  ) async {
    final service = _DeferredRegistrationService();
    final controller = EventRegistrationController(
      service,
      _event(where: 'Direkt'),
    );

    await tester.pumpWidget(_TestApp(controller));

    await tester.tap(find.text('Spara anmälan'));
    await tester.pump();

    expect(controller.status, EventRegistrationStatus.saving);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.complete();
    await tester.pumpAndSettle();
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp(this.controller);

  final EventRegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EventRegistrationScreen(controller: controller));
  }
}

EventDetails _event({
  String? where,
  bool car = false,
  bool instrument = true,
  String comment = '',
  String? selectedInstrument = 'Flöjt',
}) {
  return EventDetails(
    id: 42,
    type: 'Spelning',
    name: 'Testevent',
    place: 'Kårhuset',
    description: '',
    internalDescription: '',
    date: '2026-09-15',
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '',
    stand: '',
    signupState: where,
    coming: 0,
    notComing: 0,
    disabled: false,
    registrationAvailable: true,
    registration: EventRegistrationSelection(
      where: where,
      car: car,
      instrument: instrument,
      comment: comment,
      selectedInstrument: selectedInstrument,
      availableInstruments: const ['Flöjt', 'Piccolo'],
    ),
    attendees: const [],
  );
}

class _FakeRegistrationService implements EventRegistrationService {
  _FakeRegistrationService({this.error});

  final Object? error;
  final List<EventRegistrationRequest> requests = [];

  @override
  Future<void> saveRegistration(
    int eventId,
    EventRegistrationRequest request,
  ) async {
    requests.add(request);

    if (error != null) {
      throw error!;
    }
  }
}

class _DeferredRegistrationService implements EventRegistrationService {
  final Completer<void> _completer = Completer<void>();

  void complete() {
    _completer.complete();
  }

  @override
  Future<void> saveRegistration(int eventId, EventRegistrationRequest request) {
    return _completer.future;
  }
}
