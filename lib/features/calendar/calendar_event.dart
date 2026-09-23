class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.place,
    required this.description,
    required this.internalDescription,
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
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      place: json['place'] as String? ?? '',
      description: json['description'] as String? ?? '',
      internalDescription: json['internalDescription'] as String? ?? '',
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
    );
  }

  final int id;
  final String type;
  final String name;
  final String place;
  final String description;
  final String internalDescription;
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

  String get displayTime {
    if (signupState == 'Hålan' && halanTime.isNotEmpty) {
      return halanTime;
    }

    if (effectiveThereTime.isNotEmpty) {
      return effectiveThereTime;
    }

    if (halanTime.isNotEmpty) {
      return halanTime;
    }

    return startsTime;
  }

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

  static const rehearsalTypes = {
    'Rep',
    'Kårhusrep',
    'Balettrep',
    'Athenrep',
    'Samlingsrep',
    'Fikarep',
  };

  bool get isRehearsal => rehearsalTypes.contains(type);

  bool get isPerformance => type == 'Spelning';

  bool get isSocialEvent => type == 'Fest';

  bool isRelevantTo({required bool isBallet}) {
    if (signupState == 'Kan inte komma') {
      return false;
    }

    if (signupState == 'Hålan' || signupState == 'Direkt') {
      return true;
    }

    return switch (type) {
      'Rep' => !isBallet,
      'Balettrep' => isBallet,
      'Kårhusrep' || 'Athenrep' || 'Samlingsrep' || 'Fikarep' => true,
      _ => false,
    };
  }
}
