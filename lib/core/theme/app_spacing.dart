import 'package:flutter/material.dart';

/// Espacements standardisés pour toute l'application
class AppSpacing {
  // Espacements de base (multiples de 4)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Padding standard pour les écrans
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: md);

  // Padding pour les cartes
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(sm);

  // Espacement entre les éléments
  static const SizedBox spacingXS = SizedBox(height: xs, width: xs);
  static const SizedBox spacingSM = SizedBox(height: sm, width: sm);
  static const SizedBox spacingMD = SizedBox(height: md, width: md);
  static const SizedBox spacingLG = SizedBox(height: lg, width: lg);
  static const SizedBox spacingXL = SizedBox(height: xl, width: xl);
  static const SizedBox spacingXXL = SizedBox(height: xxl, width: xxl);

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  // Border radius pour les cartes
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius cardRadiusSmall = BorderRadius.all(Radius.circular(radiusMD));
}

