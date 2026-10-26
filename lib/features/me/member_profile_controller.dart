// -----------------------------------------------------------------------------
// member_profile_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Manages authenticated profile retrieval, editing, and session-scoped data.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import 'member_profile.dart';
import 'member_profile_api.dart';
import 'member_profile_preview_service.dart';

enum MemberProfileStatus { idle, loading, loaded, error }

/// Manages the authenticated member's profile and registration statistics.
///
/// Prevents responses from earlier requests from restoring data after the
/// authenticated session has been cleared.
class MemberProfileController extends ChangeNotifier {
  MemberProfileController(this._service);

  final MemberProfileService _service;

  MemberProfileStatus _status = MemberProfileStatus.idle;
  MemberProfile? _profile;
  MemberProfileStatistics? _statistics;
  Object? _error;
  Object? _saveError;
  bool _isSaving = false;
  int _generation = 0;

  MemberProfileStatus get status => _status;
  MemberProfile? get profile => _profile;
  MemberProfileStatistics? get statistics => _statistics;
  Object? get error => _error;
  Object? get saveError => _saveError;
  bool get isSaving => _isSaving;

  bool get isProfilePreview =>
      _service is MemberProfilePreviewService && _service.profileIsPreview;

  bool get isStatisticsPreview =>
      _service is MemberProfilePreviewService && _service.statisticsArePreview;

  /// Loads the profile without requesting statistics.
  ///
  /// Statistics are loaded separately when the user opens the statistics view.
  Future<void> load() async {
    final generation = ++_generation;

    _status = MemberProfileStatus.loading;
    _profile = null;
    _statistics = null;
    _error = null;
    _saveError = null;
    _isSaving = false;
    notifyListeners();

    try {
      final profile = await _service.getProfile();

      if (generation != _generation) {
        return;
      }

      _profile = profile;
      _status = MemberProfileStatus.loaded;
      notifyListeners();
    } catch (error) {
      if (generation != _generation) {
        return;
      }

      _error = error;
      _status = MemberProfileStatus.error;
      notifyListeners();
    }
  }

  /// Saves the authenticated member's editable profile fields.
  ///
  /// Keeps the previous profile visible until AKCore confirms the update.
  /// Returns false when saving is unavailable, fails, or becomes stale after
  /// session cleanup or a newer profile load. Failures remain in [saveError].
  Future<bool> saveProfile(MemberProfileUpdateRequest request) async {
    if (_status != MemberProfileStatus.loaded ||
        _profile == null ||
        _isSaving ||
        isProfilePreview) {
      return false;
    }

    final generation = _generation;

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final savedProfile = await _service.updateProfile(request);

      if (generation != _generation) {
        return false;
      }

      _profile = savedProfile;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (error) {
      if (generation != _generation) {
        return false;
      }

      _saveError = error;
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Retrieves the current AKCore registration statistics.
  Future<void> loadStatistics() async {
    final generation = _generation;
    _statistics = null;
    _error = null;
    notifyListeners();

    try {
      final statistics = await _service.getStatistics();

      if (generation != _generation) {
        return;
      }

      _statistics = statistics;
      notifyListeners();
    } catch (error) {
      if (generation != _generation) {
        return;
      }

      _error = error;
      notifyListeners();
    }
  }

  /// Removes all information belonging to the previous authenticated session.
  void clear() {
    _generation++;
    _profile = null;
    _statistics = null;
    _error = null;
    _saveError = null;
    _isSaving = false;
    _status = MemberProfileStatus.idle;
    notifyListeners();
  }
}
