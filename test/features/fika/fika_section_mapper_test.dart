import 'package:altekamerer/features/fika/fika_section.dart';
import 'package:altekamerer/features/fika/fika_section_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps AKCore instruments to fika sections', () {
    expect(
      fikaSectionsForInstruments([
        'Balett',
        'Flöjt',
        'Oboe',
        'Klarinett',
        'Dragspel',
        'Banjo',
        'Slagverk',
        'Altsax',
        'Tenorsax',
        'Barytonsax',
        'Horn',
        'Trombon',
        'Euphonium',
        'Tuba',
        'Trumpet',
      ]),
      {
        FikaSection.balett,
        FikaSection.flojt,
        FikaSection.klarinett,
        FikaSection.komp,
        FikaSection.sax,
        FikaSection.horn,
        FikaSection.grovbrass,
        FikaSection.trumpet,
      },
    );
  });

  test('deduplicates instruments belonging to the same fika section', () {
    expect(fikaSectionsForInstruments(['Altsax', 'Tenorsax', 'Barytonsax']), {
      FikaSection.sax,
    });
  });

  test('ignores instruments without a fika-section mapping', () {
    expect(fikaSectionsForInstruments(['Unknown instrument']), isEmpty);
  });
}
