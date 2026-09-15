import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load exposes loaded event', () async {
    final event = _event();
    final controller = EventDetailsController(
      _FakeEventDetailsService(event: event),
    );

    await controller.load(42);

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(event));
    expect(controller.error, isNull);
  });

  test('load exposes error state when service fails', () async {
    final controller = EventDetailsController(
      _FakeEventDetailsService(error: Exception('failed')),
    );

    await controller.load(42);

    expect(controller.status, EventDetailsStatus.error);
    expect(controller.event, isNull);
    expect(controller.error, isNotNull);
  });
}

EventDetails _event() {
  return const EventDetails(
    id: 42,
    type: 'Rep',
    name: 'Tisdagsrep',
    place: 'Kårhuset',
    description: 'Ordinarie repetition',
    internalDescription: '',
    date: '2026-09-15',
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '120',
    stand: '',
    signupState: 'Hålan',
    coming: 12,
    notComing: 3,
    disabled: false,
    registrationAvailable: true,
    registration: EventRegistrationSelection(
      where: 'Hålan',
      car: false,
      instrument: true,
      comment: '',
      selectedInstrument: 'Flöjt',
      availableInstruments: ['Flöjt'],
    ),
    attendees: [
      EventAttendee(
        personName: 'Test Member',
        where: 'Hålan',
        car: false,
        instrument: true,
        instrumentName: 'Flöjt',
        comment: '',
      ),
    ],
  );
}

class _FakeEventDetailsService implements EventDetailsService {
  _FakeEventDetailsService({this.event, this.error});

  final EventDetails? event;
  final Object? error;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    if (error != null) {
      throw error!;
    }

    return event!;
  }
}
