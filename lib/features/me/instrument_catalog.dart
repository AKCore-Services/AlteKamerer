// -----------------------------------------------------------------------------
// instrument_catalog.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Provides localized suggestions for AKCore's standard instruments while
//   retaining unrestricted custom instrument values.
//
// Contains:
//   - StandardInstrument: Canonical and translated names.
//   - InstrumentCatalog: Instrument lookup, normalization, and suggestions.
//
// -----------------------------------------------------------------------------

/// A standard AKCore instrument with its canonical stored name and English
/// display name.
class StandardInstrument {
  const StandardInstrument(this.canonical, this.english);

  final String canonical;
  final String english;

  String label(String languageCode) =>
      languageCode == 'en' ? english : canonical;
}

/// Mirrors AKCore's AkInstruments and instrument TranslationsService entries.
///
/// AKCore stores Swedish canonical names. The mobile editor may display
/// English labels, but must submit canonical names for recognized instruments.
/// Unknown instrument values are preserved rather than rejected.
class InstrumentCatalog {
  const InstrumentCatalog._();

  static const instruments = <StandardInstrument>[
    StandardInstrument('Dragspel', 'Accordion'),
    StandardInstrument('Altsax', 'Alto sax'),
    StandardInstrument('Balett', 'Ballet'),
    StandardInstrument('Banjo', 'Banjo'),
    StandardInstrument('Barytonsax', 'Baritone sax'),
    StandardInstrument('Euphonium', 'Euphonium'),
    StandardInstrument('Flöjt', 'Flute'),
    StandardInstrument('Horn', 'Horn'),
    StandardInstrument('Klarinett', 'Clarinet'),
    StandardInstrument('Oboe', 'Oboe'),
    StandardInstrument('Slagverk', 'Drums'),
    StandardInstrument('Tenorsax', 'Tenor sax'),
    StandardInstrument('Trombon', 'Trombone'),
    StandardInstrument('Trumpet', 'Trumpet'),
    StandardInstrument('Tuba', 'Tuba'),
  ];

  static String _normalized(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('å', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o');
  }

  static StandardInstrument? find(String value) {
    final normalized = _normalized(value);

    if (normalized.isEmpty) {
      return null;
    }

    for (final instrument in instruments) {
      if (_normalized(instrument.canonical) == normalized ||
          _normalized(instrument.english) == normalized) {
        return instrument;
      }
    }

    return null;
  }

  /// Converts recognized Swedish or English names to AKCore's stored value.
  ///
  /// Custom names retain their original text, apart from surrounding spaces.
  static String canonicalValue(String value) {
    return find(value)?.canonical ?? value.trim();
  }

  static String displayValue(String value, String languageCode) {
    return find(value)?.label(languageCode) ?? value;
  }

  static bool isCustom(String value) {
    return value.trim().isNotEmpty && find(value) == null;
  }

  /// Searches both languages so users can find an instrument using either name.
  static List<StandardInstrument> suggestions(String query) {
    final normalized = _normalized(query);

    if (normalized.isEmpty) {
      return const [];
    }

    return instruments.where((instrument) {
      return _normalized(instrument.canonical).contains(normalized) ||
          _normalized(instrument.english).contains(normalized);
    }).toList();
  }
}
