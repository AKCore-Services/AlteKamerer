// -----------------------------------------------------------------------------
// fika_section.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the AKCore fika sections used by AlteKamerer.
//
// -----------------------------------------------------------------------------

/// A section that can be assigned fika and cleaning duty in AKCore.
enum FikaSection {
  balett('Balett'),
  flojt('Flöjt'),
  klarinett('Klarinett'),
  komp('Komp'),
  sax('Sax'),
  horn('Horn'),
  grovbrass('Grovbrass'),
  trumpet('Trumpet');

  const FikaSection(this.backendValue);

  final String backendValue;

  /// Resolves an AKCore fika section name.
  ///
  /// Unknown values are ignored so stale or future backend section names do
  /// not break calendar rendering.
  static FikaSection? fromBackendValue(String value) {
    final normalized = value.trim();

    for (final section in values) {
      if (section.backendValue == normalized) {
        return section;
      }
    }

    return null;
  }
}

/// Parses AKCore's comma-separated fika collection.
///
/// Empty, unknown, and duplicate values are ignored while canonical AKCore
/// section ordering is preserved.
Set<FikaSection> parseFikaCollection(String value) {
  final assigned = <FikaSection>{};

  for (final item in value.split(',')) {
    final section = FikaSection.fromBackendValue(item);

    if (section != null) {
      assigned.add(section);
    }
  }

  return {
    for (final section in FikaSection.values)
      if (assigned.contains(section)) section,
  };
}
