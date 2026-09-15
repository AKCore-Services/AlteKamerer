import 'package:altekamerer/features/notifications/notification_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores pending event until consumed', () {
    final controller = NotificationNavigationController();

    controller.openEvent(42);

    expect(controller.pendingEventId, 42);
    expect(controller.consumePendingEventId(), 42);
    expect(controller.pendingEventId, isNull);
  });

  test('new notification replaces unconsumed target', () {
    final controller = NotificationNavigationController();

    controller.openEvent(42);
    controller.openEvent(84);

    expect(controller.consumePendingEventId(), 84);
  });

  test('consume with no pending event returns null', () {
    final controller = NotificationNavigationController();

    expect(controller.consumePendingEventId(), isNull);
  });
}
