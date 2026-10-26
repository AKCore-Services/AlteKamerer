import 'package:altekamerer/features/me/instrument_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue contains all 15 standard AKCore instruments', () {
    expect(InstrumentCatalog.instruments, hasLength(15));

    expect(
      InstrumentCatalog.instruments.map((instrument) => instrument.canonical),
      containsAll([
        'Dragspel',
        'Flöjt',
        'Klarinett',
        'Slagverk',
        'Trombon',
        'Trumpet',
        'Tuba',
      ]),
    );
  });

  test('recognized translations use canonical AKCore values', () {
    expect(InstrumentCatalog.canonicalValue('Trombone'), 'Trombon');
    expect(InstrumentCatalog.canonicalValue('Flute'), 'Flöjt');
    expect(InstrumentCatalog.canonicalValue('Accordion'), 'Dragspel');
    expect(InstrumentCatalog.canonicalValue('Drums'), 'Slagverk');
    expect(InstrumentCatalog.canonicalValue('alto SAX'), 'Altsax');
    expect(InstrumentCatalog.canonicalValue('Flöjt'), 'Flöjt');
  });

  test('suggestions match Swedish, English and unaccented input', () {
    expect(
      InstrumentCatalog.suggestions('trombo')
          .map((instrument) => instrument.canonical),
      contains('Trombon'),
    );

    expect(
      InstrumentCatalog.suggestions('flute')
          .map((instrument) => instrument.canonical),
      contains('Flöjt'),
    );

    expect(
      InstrumentCatalog.suggestions('floj')
          .map((instrument) => instrument.canonical),
      contains('Flöjt'),
    );

    expect(InstrumentCatalog.suggestions(''), isEmpty);
  });

  test('display labels follow locale without changing stored values', () {
    expect(InstrumentCatalog.displayValue('Trombon', 'en'), 'Trombone');
    expect(InstrumentCatalog.displayValue('Trombone', 'sv'), 'Trombon');
    expect(InstrumentCatalog.canonicalValue('Trombone'), 'Trombon');
  });

  test('custom instruments remain supported and unchanged', () {
    expect(InstrumentCatalog.isCustom('Nyckelharpa'), isTrue);
    expect(InstrumentCatalog.isCustom('Trumpet'), isFalse);
    expect(InstrumentCatalog.isCustom(''), isFalse);

    expect(InstrumentCatalog.canonicalValue('  Nyckelharpa  '), 'Nyckelharpa');
    expect(InstrumentCatalog.displayValue('Nyckelharpa', 'en'), 'Nyckelharpa');
  });
}
