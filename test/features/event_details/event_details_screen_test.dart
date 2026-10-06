import 'dart:async';

import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_cache.dart';
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
          stand: 'Stå och gå',
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
    expect(find.text('Speltid'), findsOneWidget);
    expect(find.text('120 min'), findsOneWidget);
    expect(find.text('Speltyp'), findsOneWidget);
    expect(find.text('Stå och gå'), findsOneWidget);
    expect(find.text('Ordinarie repetition'), findsOneWidget);
    expect(find.text('Intern information'), findsOneWidget);
    expect(find.text('Ta med marschmapp.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Din status: Hålan'), findsOneWidget);
    expect(find.text('12 kommer · 3 kommer inte'), findsNothing);
  });

  testWidgets('shows attendees grouped like the AKCore event page', (
    WidgetTester tester,
  ) async {
    final controller = EventDetailsController(
      FakeEventDetailsService(
        event: _event(
          attendees: const [
            EventAttendee(
              personName: 'Anna Altsax',
              where: 'Direkt',
              car: false,
              instrument: true,
              instrumentName: 'Altsax',
              comment: '',
            ),
            EventAttendee(
              personName: 'Bertil Altsax',
              where: 'Hålan',
              car: true,
              instrument: false,
              instrumentName: 'Altsax',
              comment: 'Tar med notställ.',
            ),
            EventAttendee(
              personName: 'Cecilia Balett',
              where: 'Hålan',
              car: false,
              instrument: true,
              instrumentName: 'Balett',
              comment: '',
            ),
            EventAttendee(
              personName: r'David \Frånvarande',
              where: 'Kan inte komma',
              car: false,
              instrument: true,
              instrumentName: 'Trumpet',
              comment: 'Bortrest.',
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Deltagare'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deltagare'), findsOneWidget);
    expect(find.text('Kommer'), findsOneWidget);
    expect(find.text('Kommer inte'), findsOneWidget);

    expect(find.text('Altsax · 2'), findsOneWidget);
    expect(find.text('Balett · 1'), findsOneWidget);

    expect(find.text('Anna Altsax'), findsOneWidget);
    expect(find.text('Direkt'), findsOneWidget);

    expect(find.text('Bertil Altsax'), findsOneWidget);
    expect(
      find.text('Hålan · Behöver transport av instrument · Har bil'),
      findsOneWidget,
    );
    expect(find.text('Tar med notställ.'), findsOneWidget);

    expect(find.text('Cecilia Balett'), findsOneWidget);

    expect(find.text('David Frånvarande'), findsOneWidget);
    expect(find.text('Bortrest.'), findsOneWidget);
  });

  testWidgets(
    'cached event identifies cache age and disables registration changes',
    (WidgetTester tester) async {
      final cachedAt = DateTime.utc(2026, 10, 5, 6, 30);
      final controller = EventDetailsController(
        FakeEventDetailsService(error: StateError('event failed')),
        cache: _FakeEventDetailsCache(
          value: CachedEventDetails(
            event: _event(signupState: 'Direkt'),
            cachedAt: cachedAt,
          ),
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          controller: controller,
          onRegistrationPressed: (_) {
            fail('Cached registration action must remain disabled.');
          },
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(controller.isShowingCachedData, isTrue);
      expect(
        find.textContaining('Använder cache från', findRichText: true),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Ändra anmälan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Anslut till AKCore för att ändra anmälan.'),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ändra anmälan'),
      );

      expect(button.onPressed, isNull);
    },
  );

  testWidgets('pull to refresh reloads the displayed event', (
    WidgetTester tester,
  ) async {
    final service = FakeEventDetailsService(event: _event());
    final controller = EventDetailsController(service);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    expect(find.text('Inte anmäld'), findsOneWidget);

    service.event = _event(signupState: 'Direkt');

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Din status: Direkt'), findsOneWidget);
  });

  testWidgets('large text reflows event detail rows', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = EventDetailsController(
      FakeEventDetailsService(event: _event()),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();

    expect(find.text('Datum'), findsOneWidget);
    expect(find.text('15/09/2026'), findsOneWidget);
    expect(find.text('Plats'), findsOneWidget);
    expect(find.text('Kårhuset'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  String stand = '',
  bool disabled = false,
  bool registrationAvailable = true,
  List<EventAttendee> attendees = const [],
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
    stand: stand,
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
    attendees: attendees,
  );
}

class _FakeEventDetailsCache implements EventDetailsCache {
  _FakeEventDetailsCache({this.value});

  CachedEventDetails? value;

  @override
  Future<CachedEventDetails?> read(int eventId) async {
    final value = this.value;

    if (value == null || value.event.id != eventId) {
      return null;
    }

    return value;
  }

  @override
  Future<void> write(EventDetails event, {required DateTime cachedAt}) async {
    value = CachedEventDetails(event: event, cachedAt: cachedAt);
  }

  @override
  Future<void> clear() async {
    value = null;
  }
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
