import 'package:altekamerer/features/navigation/app_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores pending event until consumed', () {
    final controller = AppNavigationController();

    controller.openEvent(42);

    expect(controller.pendingEventId, 42);
    expect(
      controller.pendingRequest,
      isA<EventNavigationRequest>().having(
        (request) => request.eventId,
        'eventId',
        42,
      ),
    );

    final request = controller.consumePendingRequest();

    expect(
      request,
      isA<EventNavigationRequest>().having(
        (request) => request.eventId,
        'eventId',
        42,
      ),
    );
    expect(controller.pendingRequest, isNull);
    expect(controller.pendingEventId, isNull);
  });

  test('queues parsed navigation request directly', () {
    final controller = AppNavigationController();
    const request = EventNavigationRequest(84);

    controller.openRequest(request);

    expect(controller.pendingRequest, same(request));
    expect(controller.pendingEventId, 84);
  });

  test('stores pending calendar until consumed', () {
    final controller = AppNavigationController();

    controller.openCalendar();

    expect(controller.pendingRequest, isA<CalendarNavigationRequest>());
    expect(controller.pendingEventId, isNull);

    expect(
      controller.consumePendingRequest(),
      isA<CalendarNavigationRequest>(),
    );
    expect(controller.pendingRequest, isNull);
  });

  test('new navigation request replaces unconsumed target', () {
    final controller = AppNavigationController();

    controller.openEvent(42);
    controller.openCalendar();

    expect(
      controller.consumePendingRequest(),
      isA<CalendarNavigationRequest>(),
    );
  });

  test('invalid event id is ignored', () {
    final controller = AppNavigationController();

    controller.openEvent(0);

    expect(controller.pendingRequest, isNull);
  });

  test('consume with no pending request returns null', () {
    final controller = AppNavigationController();

    expect(controller.consumePendingRequest(), isNull);
  });
}
