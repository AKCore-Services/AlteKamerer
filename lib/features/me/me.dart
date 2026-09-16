class Me {
  const Me({
    required this.displayName,
    required this.isMember,
    required this.isBallet,
    required this.availableInstruments,
  });

  factory Me.fromJson(Map<String, dynamic> json) {
    final instruments = json['availableInstruments'];

    if (instruments is! List) {
      throw const FormatException('Expected available instruments array.');
    }

    return Me(
      displayName: json['displayName'] as String? ?? '',
      isMember: json['isMember'] as bool,
      isBallet: json['isBallet'] as bool,
      availableInstruments: instruments.cast<String>(),
    );
  }

  final String displayName;
  final bool isMember;
  final bool isBallet;
  final List<String> availableInstruments;
}
