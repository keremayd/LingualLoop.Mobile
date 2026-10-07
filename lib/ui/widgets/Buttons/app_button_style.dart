import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:math' as math;

/// One switch for the app-wide Karty button treatment. Turning it off restores
/// each caller's previous depth/radius without changing its outer layout.
abstract final class AppButtonStyle {
  static const bool roundedDepth = AppShapeStyle.roundedDepth;

  // Ratios measured from the approved Karty controls, including the base.
  static const _actionDepth = 13.5 / 131.25;
  static const _actionRadius = 36 / 131.25;
  static const _iconDepth = 12.375 / 89.625;
  static const _iconRadius = 24.75 / 84.75;

  static AppButtonGeometry resolve({
    required double width,
    required double totalHeight,
    required double legacyRadius,
    required double legacyDepth,
    double? roundedDepthOverride,
    bool? icon,
  }) {
    if (!roundedDepth) {
      return AppButtonGeometry(
        depth: legacyDepth,
        radius: legacyRadius,
        faceHeight: totalHeight - legacyDepth,
      );
    }
    final isIcon = icon ?? width <= totalHeight * 1.35;
    final depth = roundedDepthOverride ??
        totalHeight * (isIcon ? _iconDepth : _actionDepth);
    return AppButtonGeometry(
      depth: depth,
      radius:
          math.min(width, totalHeight) * (isIcon ? _iconRadius : _actionRadius),
      faceHeight: totalHeight - depth,
    );
  }

  // Large tappable content tiles retain their card proportions rather than
  // inheriting the radius of a short action button.
  static double tileRadius(double legacy) => AppShapeStyle.cardRadius(legacy);
  static double tileDepth(double legacy) => AppShapeStyle.cardDepth(legacy);
}

class AppButtonGeometry {
  const AppButtonGeometry({
    required this.depth,
    required this.radius,
    required this.faceHeight,
  });
  final double depth;
  final double radius;
  final double faceHeight;
}
