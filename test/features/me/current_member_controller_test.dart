import 'package:altekamerer/features/me/current_member_controller.dart';
import 'package:altekamerer/features/me/me.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updates and clears current member', () {
    final controller = CurrentMemberController();
    var notifications = 0;

    controller.addListener(() {
      notifications++;
    });

    const member = Me(
      displayName: 'Test',
      isMember: true,
      isBallet: false,
      availableInstruments: ['Altsax'],
    );

    controller.update(member);

    expect(controller.member, same(member));
    expect(notifications, 1);

    controller.clear();

    expect(controller.member, isNull);
    expect(notifications, 2);
  });

  test('clearing empty member state does not notify', () {
    final controller = CurrentMemberController();
    var notifications = 0;

    controller.addListener(() {
      notifications++;
    });

    controller.clear();

    expect(controller.member, isNull);
    expect(notifications, 0);
  });
}
