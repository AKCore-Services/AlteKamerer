import 'package:flutter/material.dart';

/// AKCore brand colors shared by the application's Material theme.
///
/// The accessible red variants provide alternatives for foreground and
/// border treatments where the primary brand red is unsuitable.
abstract final class AkColors {
  static const Color red = Color(0xFFB10000);
  static const Color accessibleRed = Color(0xFFE86B6B);
  static const Color accessibleBorderRed = Color(0xFFC74444);
  static const Color grey = Color(0xFF2D2727);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFDDDDDD);
  static const Color black = Color(0xFF000000);

  static const Color deepRed = Color(0xFF6E1601);
  static const Color darkestRed = Color(0xFF430800);
}
