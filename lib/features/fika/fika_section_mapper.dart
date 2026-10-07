// -----------------------------------------------------------------------------
// fika_section_mapper.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Maps AKCore member instruments to the fika sections used by the mobile
//   calendar.
//
// -----------------------------------------------------------------------------

import 'fika_section.dart';

/// Resolves mobile fika presentation sections from AKCore instruments.
///
/// This mapping is client-side presentation logic for AlteKamerer's calendar,
/// not an AKCore backend business-rule resolver. Unmapped instruments are
/// ignored, and multiple instruments resolving to one section are deduplicated.
Set<FikaSection> fikaSectionsForInstruments(Iterable<String> instruments) {
  final sections = <FikaSection>{};

  for (final instrument in instruments) {
    final section = switch (instrument) {
      'Balett' => FikaSection.balett,
      'Flöjt' || 'Oboe' => FikaSection.flojt,
      'Klarinett' => FikaSection.klarinett,
      'Dragspel' || 'Banjo' || 'Slagverk' => FikaSection.komp,
      'Altsax' || 'Tenorsax' || 'Barytonsax' => FikaSection.sax,
      'Horn' => FikaSection.horn,
      'Trombon' || 'Euphonium' || 'Tuba' => FikaSection.grovbrass,
      'Trumpet' => FikaSection.trumpet,
      _ => null,
    };

    if (section != null) {
      sections.add(section);
    }
  }

  return sections;
}
