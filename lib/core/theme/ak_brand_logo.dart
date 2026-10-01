// -----------------------------------------------------------------------------
// ak_brand_logo.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Selects and displays the appropriate AKCore branding asset.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'ak_assets.dart';

/// Available organization logo variants and application mark.
enum AkBrandLogoVariant { full, mobile, alteKamereren, mark }

/// Displays an AKCore branding asset selected by [variant].
///
/// Uses the shared asset registry and supplies an accessible image label.
class AkBrandLogo extends StatelessWidget {
  const AkBrandLogo({
    super.key,
    this.variant = AkBrandLogoVariant.full,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final AkBrandLogoVariant variant;
  final double? height;
  final double? width;
  final BoxFit fit;

  String get _assetName {
    return switch (variant) {
      AkBrandLogoVariant.full => AkAssets.fullLogo,
      AkBrandLogoVariant.mobile => AkAssets.mobileLogo,
      AkBrandLogoVariant.alteKamereren => AkAssets.alteKamererenLogo,
      AkBrandLogoVariant.mark => AkAssets.appMark512,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetName,
      height: height,
      width: width,
      fit: fit,
      semanticLabel: 'Alte Kamereren & Kamrérbaletten',
    );
  }
}
