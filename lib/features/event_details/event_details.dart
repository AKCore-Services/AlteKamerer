// -----------------------------------------------------------------------------
// event_details.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines detailed event data, the member's registration selection, and attendee information.
//
// -----------------------------------------------------------------------------

/// Represents the detailed event information returned by AKCore.
///
/// Includes event metadata, the member's registration selection, and the
/// attendee collection used by the event details and registration screens.
class EventDetails {
  const EventDetails({
    required this.id,
    required this.type,
    required this.name,
    required this.place,
    required this.description,
    required this.internalDescription,
    this.fikaCollection = '',
    required this.date,
    required this.halanTime,
    required this.thereTime,
    required this.startsTime,
    required this.playDuration,
    required this.stand,
    required this.signupState,
    required this.coming,
    required this.notComing,
    required this.disabled,
    required this.registrationAvailable,
    required this.registration,
    required this.attendees,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    final registrationJson = json['registration'];
    final attendeesJson = json['attendees'];

    if (registrationJson is! Map<String, dynamic>) {
      throw const FormatException('Expected event registration object.');
    }

    if (attendeesJson is! List) {
      throw const FormatException('Expected event attendees array.');
    }

    return EventDetails(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      place: json['place'] as String? ?? '',
      description: json['description'] as String? ?? '',
      internalDescription: json['internalDescription'] as String? ?? '',
      fikaCollection: json['fikaCollection'] as String? ?? '',
      date: json['date'] as String,
      halanTime: json['halanTime'] as String? ?? '',
      thereTime: json['thereTime'] as String? ?? '',
      startsTime: json['startsTime'] as String? ?? '',
      playDuration: json['playDuration'] as String? ?? '',
      stand: json['stand'] as String? ?? '',
      signupState: json['signupState'] as String?,
      coming: json['coming'] as int,
      notComing: json['notComing'] as int,
      disabled: json['disabled'] as bool,
      registrationAvailable: json['registrationAvailable'] as bool,
      registration: EventRegistrationSelection.fromJson(registrationJson),
      attendees: attendeesJson.map((attendee) {
        if (attendee is! Map<String, dynamic>) {
          throw const FormatException('Expected event attendee object.');
        }

        return EventAttendee.fromJson(attendee);
      }).toList(),
    );
  }

  /// Serializes these event details for secure offline caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'place': place,
      'description': description,
      'internalDescription': internalDescription,
      'fikaCollection': fikaCollection,
      'date': date,
      'halanTime': halanTime,
      'thereTime': thereTime,
      'startsTime': startsTime,
      'playDuration': playDuration,
      'stand': stand,
      'signupState': signupState,
      'coming': coming,
      'notComing': notComing,
      'disabled': disabled,
      'registrationAvailable': registrationAvailable,
      'registration': registration.toJson(),
      'attendees': attendees.map((attendee) => attendee.toJson()).toList(),
    };
  }

  final int id;
  final String type;
  final String name;
  final String place;
  final String description;
  final String internalDescription;
  final String fikaCollection;
  final String date;
  final String halanTime;
  final String thereTime;
  final String startsTime;
  final String playDuration;
  final String stand;
  final String? signupState;
  final int coming;
  final int notComing;
  final bool disabled;
  final bool registrationAvailable;
  final EventRegistrationSelection registration;
  final List<EventAttendee> attendees;

  /// Returns the arrival time appropriate for this event type.
  ///
  /// Orchestra and ballet rehearsals use Hålan time. Other events
  /// use the ordinary arrival time supplied by AKCore.
  String get effectiveThereTime {
    if (type == 'Rep' || type == 'Balettrep') {
      return halanTime;
    }

    return thereTime;
  }

  bool get isRegistered => signupState != null && signupState!.isNotEmpty;

  bool get isAttending {
    return signupState == 'Hålan' || signupState == 'Direkt';
  }

  bool get isRegisteredNotAttending => signupState == 'Kan inte komma';
}

/// Represents the member's current registration form values.
///
/// Includes the available instruments supplied by the backend.
class EventRegistrationSelection {
  const EventRegistrationSelection({
    required this.where,
    required this.car,
    required this.instrument,
    required this.comment,
    required this.selectedInstrument,
    required this.availableInstruments,
  });

  factory EventRegistrationSelection.fromJson(Map<String, dynamic> json) {
    final instrumentsJson = json['availableInstruments'];

    if (instrumentsJson is! List) {
      throw const FormatException('Expected available instruments array.');
    }

    return EventRegistrationSelection(
      where: json['where'] as String?,
      car: json['car'] as bool,
      instrument: json['instrument'] as bool,
      comment: json['comment'] as String? ?? '',
      selectedInstrument: json['selectedInstrument'] as String?,
      availableInstruments: instrumentsJson.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'where': where,
      'car': car,
      'instrument': instrument,
      'comment': comment,
      'selectedInstrument': selectedInstrument,
      'availableInstruments': availableInstruments,
    };
  }

  final String? where;
  final bool car;
  final bool instrument;
  final String comment;
  final String? selectedInstrument;
  final List<String> availableInstruments;
}

/// Represents an attendee entry returned with event details.
class EventAttendee {
  const EventAttendee({
    required this.personName,
    required this.where,
    required this.car,
    required this.instrument,
    required this.instrumentName,
    required this.comment,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      personName: json['personName'] as String? ?? '',
      where: json['where'] as String?,
      car: json['car'] as bool,
      instrument: json['instrument'] as bool,
      instrumentName: json['instrumentName'] as String?,
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personName': personName,
      'where': where,
      'car': car,
      'instrument': instrument,
      'instrumentName': instrumentName,
      'comment': comment,
    };
  }

  final String personName;
  final String? where;
  final bool car;
  final bool instrument;
  final String? instrumentName;
  final String comment;
}
