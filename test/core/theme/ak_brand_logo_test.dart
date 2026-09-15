import 'package:altekamerer/core/theme/ak_assets.dart';
import 'package:altekamerer/core/theme/ak_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('full logo uses the AKCore full wordmark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AkBrandLogo()));

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, AkAssets.fullLogo);
  });

  testWidgets('compact mark uses the high-resolution AKCore app mark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AkBrandLogo(variant: AkBrandLogoVariant.mark)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, AkAssets.appMark512);
  });

  testWidgets('mobile logo uses the existing AKCore mobile wordmark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AkBrandLogo(variant: AkBrandLogoVariant.mobile)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, AkAssets.mobileLogo);
  });
}
