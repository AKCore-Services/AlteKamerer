import 'package:flutter/material.dart';

import 'ak_assets.dart';

enum AkBrandLogoVariant { full, mobile, alteKamereren, mark }

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
