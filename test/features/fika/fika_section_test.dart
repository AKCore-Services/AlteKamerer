import 'package:altekamerer/features/fika/fika_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves all AKCore fika section values', () {
    expect(FikaSection.fromBackendValue('Balett'), FikaSection.balett);
    expect(FikaSection.fromBackendValue('Flöjt'), FikaSection.flojt);
    expect(FikaSection.fromBackendValue('Klarinett'), FikaSection.klarinett);
    expect(FikaSection.fromBackendValue('Komp'), FikaSection.komp);
    expect(FikaSection.fromBackendValue('Sax'), FikaSection.sax);
    expect(FikaSection.fromBackendValue('Horn'), FikaSection.horn);
    expect(FikaSection.fromBackendValue('Grovbrass'), FikaSection.grovbrass);
    expect(FikaSection.fromBackendValue('Trumpet'), FikaSection.trumpet);
  });

  test('trims section values and rejects unknown values', () {
    expect(FikaSection.fromBackendValue(' Sax '), FikaSection.sax);
    expect(FikaSection.fromBackendValue(''), isNull);
    expect(FikaSection.fromBackendValue('Unknown'), isNull);
  });

  test('parses comma-separated fika collections in canonical order', () {
    expect(parseFikaCollection('Sax, Balett,Sax,Unknown,Trumpet'), {
      FikaSection.balett,
      FikaSection.sax,
      FikaSection.trumpet,
    });
  });

  test('parses empty fika collection as no sections', () {
    expect(parseFikaCollection(''), isEmpty);
  });
}
