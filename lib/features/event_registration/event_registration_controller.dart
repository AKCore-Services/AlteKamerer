// -----------------------------------------------------------------------------
// event_registration_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Manages registration form state, validation, and submission.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../core/diagnostics/diagnostic_error_details.dart';
import '../../core/diagnostics/diagnostics_service.dart';

import '../event_details/event_details.dart';
import 'event_registration_api.dart';

enum EventRegistrationStatus { idle, saving, saved, error }

/// Coordinates editing and saving a member's event registration.
///
/// Initializes the form from [EventDetails], validates the selected
/// registration choice, and exposes saving and error states to the UI.
class EventRegistrationController extends ChangeNotifier {
  EventRegistrationController(
    this._registrationService,
    EventDetails event, {
    this._diagnostics,
  }) : _eventId = event.id,
       _where = event.registration.where,
       _car = event.registration.car,
       _instrument = event.registration.instrument,
       _comment = event.registration.comment,
       _selectedInstrument = event.registration.selectedInstrument,
       availableInstruments = List.unmodifiable(
         event.registration.availableInstruments,
       );

  final EventRegistrationService _registrationService;
  final DiagnosticsService? _diagnostics;
  final int _eventId;

  EventRegistrationStatus _status = EventRegistrationStatus.idle;
  String? _where;
  bool _car;
  bool _instrument;
  String _comment;
  String? _selectedInstrument;
  Object? _error;

  final List<String> availableInstruments;

  EventRegistrationStatus get status => _status;

  String? get where => _where;

  bool get car => _car;

  /// Whether the member needs instrument transport.
  ///
  /// The backend `instrument` field uses the opposite boolean meaning,
  /// so this UI-facing value is intentionally inverted.
  bool get needsInstrumentTransport => !_instrument;

  String get comment => _comment;

  String? get selectedInstrument => _selectedInstrument;

  Object? get error => _error;

  bool get isSaving => _status == EventRegistrationStatus.saving;

  void setWhere(String? value) {
    if (_where == value) {
      return;
    }

    _where = value;
    _clearResultState();
    notifyListeners();
  }

  void setCar(bool value) {
    if (_car == value) {
      return;
    }

    _car = value;
    _clearResultState();
    notifyListeners();
  }

  /// Sets whether the member needs instrument transport.
  ///
  /// The UI-facing [value] is inverted before storage because the backend
  /// `instrument` field represents the opposite choice.
  void setNeedsInstrumentTransport(bool value) {
    final instrument = !value;

    if (_instrument == instrument) {
      return;
    }

    _instrument = instrument;
    _clearResultState();
    notifyListeners();
  }

  void setComment(String value) {
    if (_comment == value) {
      return;
    }

    _comment = value;
    _clearResultState();
    notifyListeners();
  }

  void setSelectedInstrument(String? value) {
    if (_selectedInstrument == value) {
      return;
    }

    _selectedInstrument = value;
    _clearResultState();
    notifyListeners();
  }

  /// Validates and submits the current registration.
  ///
  /// Returns `true` and enters [EventRegistrationStatus.saved] when AKCore
  /// accepts the registration.
  ///
  /// Returns `false` and enters [EventRegistrationStatus.error] if no
  /// registration choice is selected or the request fails. The failure is
  /// available through [error]; API failures are also recorded when
  /// diagnostics are configured.
  ///
  /// Submission failures are represented in controller state rather than
  /// being rethrown to the UI.
  Future<bool> save() async {
    final where = _where;

    if (where == null || where.isEmpty) {
      _error = const EventRegistrationValidationError();
      _status = EventRegistrationStatus.error;
      notifyListeners();
      return false;
    }

    _status = EventRegistrationStatus.saving;
    _error = null;
    notifyListeners();

    try {
      await _registrationService.saveRegistration(
        _eventId,
        EventRegistrationRequest(
          where: where,
          car: _car,
          instrument: _instrument,
          comment: _comment,
          selectedInstrument: _selectedInstrument,
        ),
      );

      _status = EventRegistrationStatus.saved;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _error = error;
      _status = EventRegistrationStatus.error;
      await _diagnostics?.recordError(
        subsystem: 'Registration',
        message: 'Event registration save failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      notifyListeners();
      return false;
    }
  }

  void _clearResultState() {
    if (_status == EventRegistrationStatus.saved ||
        _status == EventRegistrationStatus.error) {
      _status = EventRegistrationStatus.idle;
      _error = null;
    }
  }
}

/// Indicates that the registration form has no selected choice.
class EventRegistrationValidationError implements Exception {
  const EventRegistrationValidationError();
}
