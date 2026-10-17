import 'package:flutter/material.dart';

/// الأبعاد والمسافات وأقطار الحواف الموحدة للتطبيق
class AppDimensions {
  AppDimensions._();

  // --- مسافات عامة (Spacing) ---
  static const double spaceNone = 0.0;
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 6.0;
  static const double spaceM = 8.0;
  static const double spaceL = 12.0;
  static const double spaceXL = 16.0;
  static const double space2XL = 20.0;
  static const double space3XL = 24.0;
  static const double space4XL = 32.0;

  // --- الحشوات المسبقة (Padding Presets) ---
  static const EdgeInsets paddingNone = EdgeInsets.zero;
  static const EdgeInsets paddingAllXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingAllS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingAllM = EdgeInsets.all(12.0);
  static const EdgeInsets paddingAllL = EdgeInsets.all(16.0);
  static const EdgeInsets paddingAllXL = EdgeInsets.all(20.0);
  static const EdgeInsets paddingScreen = EdgeInsets.all(16.0);
  static const EdgeInsets paddingCard =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets paddingTile =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0);
  static const EdgeInsets paddingModal =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0);
  static const EdgeInsets paddingButton =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets paddingInput =
      EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);
  static const EdgeInsets paddingInputDense =
      EdgeInsets.symmetric(horizontal: 14.0);
  static const EdgeInsets paddingChip =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
  static const EdgeInsets paddingTag =
      EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0);
  static const EdgeInsets paddingMiniTag =
      EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0);
  static const EdgeInsets paddingSegment =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // --- أنصاف أقطار الزوايا (Corner Radius Values) ---
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 10.0;
  static const double radiusXL = 12.0;
  static const double radius2XL = 14.0;
  static const double radius3XL = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusFull = 999.0;

  // --- كائنات BorderRadius الموحدة ---
  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusXS =
      BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusS =
      BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM =
      BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL =
      BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadius2XL =
      BorderRadius.all(Radius.circular(radius2XL));
  static const BorderRadius borderRadius3XL =
      BorderRadius.all(Radius.circular(radius3XL));
  static const BorderRadius borderRadiusCard =
      BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(radiusFull));

  // --- الارتفاعات والأحجام (Component Sizes & Heights) ---
  static const double buttonHeight = 46.0;
  static const double buttonHeightTall = 48.0;
  static const double inputHeight = 48.0;
  static const double segmentHeight = 44.0;
  static const double modalMaxWidth = 480.0;
  static const double dialogMaxWidth = 320.0;
  static const double fuelCardMaxWidth = 420.0;
  static const double fuelCardMetricsMaxWidth = 380.0;
  static const double avatarSize = 48.0;
  static const double slidableActionWidth = 66.0;
  static const double slidableTotalWidth = 198.0;

  // --- أحجام الأيقونات (Icon Sizes) ---
  static const double iconMicro = 13.0;
  static const double iconMini = 14.0;
  static const double iconSmall = 16.0;
  static const double iconRegular = 18.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconExtraLarge = 28.0;
  static const double iconDisplay = 40.0;
  static const double iconEmptyState = 56.0;

  // --- سماكات الحدود (Border Widths) ---
  static const double borderWidthHairline = 0.5;
  static const double borderWidthLight = 0.8;
  static const double borderWidthThin = 1.0;
  static const double borderWidthRegular = 1.2;
  static const double borderWidthThick = 1.8;

  // --- الفواصل (Dividers) ---
  static const double dividerHeight = 1.0;
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;
  static const double dividerIndentCompact = 12.0;
}
