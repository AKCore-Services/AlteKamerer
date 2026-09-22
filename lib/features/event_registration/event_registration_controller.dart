import 'package:flutter/foundation.dart';

import '../event_details/event_details.dart';
import 'event_registration_api.dart';

enum EventRegistrationStatus { idle, saving, saved, error }

class EventRegistrationController extends ChangeNotifier {
  EventRegistrationController(this._registrationService, EventDetails event)
    : _eventId = event.id,
      _where = event.registration.where,
      _car = event.registration.car,
      _instrument = event.registration.instrument,
      _comment = event.registration.comment,
      _selectedInstrument = event.registration.selectedInstrument,
      availableInstruments = List.unmodifiable(
        event.registration.availableInstruments,
      );

  final EventRegistrationService _registrationService;
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

  bool get instrument => _instrument;

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

  void setInstrument(bool value) {
    if (_instrument == value) {
      return;
    }

    _instrument = value;
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
    } catch (error) {
      _error = error;
      _status = EventRegistrationStatus.error;
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

class EventRegistrationValidationError implements Exception {
  const EventRegistrationValidationError();
}
