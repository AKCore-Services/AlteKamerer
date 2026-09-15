import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:altekamerer/features/event_registration/event_registration_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initializes from existing event registration', () {
    final controller = EventRegistrationController(
      _FakeRegistrationService(),
      _event(
        where: 'Direkt',
        car: true,
        instrument: false,
        comment: 'Kommer direkt',
        selectedInstrument: 'Flöjt',
      ),
    );

    expect(controller.where, 'Direkt');
    expect(controller.car, isTrue);
    expect(controller.instrument, isFalse);
    expect(controller.comment, 'Kommer direkt');
    expect(controller.selectedInstrument, 'Flöjt');
    expect(controller.availableInstruments, ['Flöjt', 'Piccolo']);
    expect(controller.status, EventRegistrationStatus.idle);
  });

  test('save submits current registration values', () async {
    final service = _FakeRegistrationService();
    final controller = EventRegistrationController(service, _event());

    controller.setWhere('Hålan');
    controller.setCar(true);
    controller.setInstrument(false);
    controller.setComment('Testkommentar');
    controller.setSelectedInstrument('Piccolo');

    final result = await controller.save();

    expect(result, isTrue);
    expect(controller.status, EventRegistrationStatus.saved);
    expect(controller.error, isNull);

    expect(service.eventIds, [42]);
    expect(service.requests, hasLength(1));

    final request = service.requests.single;

    expect(request.where, 'Hålan');
    expect(request.car, isTrue);
    expect(request.instrument, isFalse);
    expect(request.comment, 'Testkommentar');
    expect(request.selectedInstrument, 'Piccolo');
  });

  test('save requires where before calling backend', () async {
    final service = _FakeRegistrationService();
    final controller = EventRegistrationController(service, _event());

    final result = await controller.save();

    expect(result, isFalse);
    expect(controller.status, EventRegistrationStatus.error);
    expect(controller.error, isA<EventRegistrationValidationError>());
    expect(service.requests, isEmpty);
  });

  test('save exposes backend failure', () async {
    final service = _FakeRegistrationService(
      error: Exception('registration failed'),
    );
    final controller = EventRegistrationController(
      service,
      _event(where: 'Direkt'),
    );

    final result = await controller.save();

    expect(result, isFalse);
    expect(controller.status, EventRegistrationStatus.error);
    expect(controller.error, isNotNull);
  });

  test('editing field clears previous result state', () async {
    final service = _FakeRegistrationService();
    final controller = EventRegistrationController(
      service,
      _event(where: 'Direkt'),
    );

    expect(await controller.save(), isTrue);
    expect(controller.status, EventRegistrationStatus.saved);

    controller.setComment('Ny kommentar');

    expect(controller.status, EventRegistrationStatus.idle);
    expect(controller.error, isNull);
  });
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

  final List<int> eventIds = [];
  final List<EventRegistrationRequest> requests = [];

  @override
  Future<void> saveRegistration(
    int eventId,
    EventRegistrationRequest request,
  ) async {
    eventIds.add(eventId);
    requests.add(request);

    if (error != null) {
      throw error!;
    }
  }
}
