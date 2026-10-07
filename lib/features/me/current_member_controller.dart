// -----------------------------------------------------------------------------
// current_member_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Holds member data already retrieved for the authenticated session.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import 'me.dart';

/// Exposes the most recently retrieved authenticated member.
///
/// Member data is populated by existing application synchronization rather than
/// triggering a separate `/me` request for individual features.
class CurrentMemberController extends ChangeNotifier {
  Me? _member;

  Me? get member => _member;

  /// Replaces the current member and notifies listeners.
  void update(Me member) {
    _member = member;
    notifyListeners();
  }

  /// Removes session-scoped member data.
  void clear() {
    if (_member == null) {
      return;
    }

    _member = null;
    notifyListeners();
  }
}
