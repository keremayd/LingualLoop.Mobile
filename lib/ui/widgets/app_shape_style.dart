/// Shared experiment for button and card geometry. Disable the same flag to
/// restore all previous radii, bottom lips and outline widths together.
abstract final class AppShapeStyle {
  static const bool roundedDepth = bool.fromEnvironment(
    'LINGUALLOOP_ROUNDED_BUTTONS',
    defaultValue: true,
  );

  static double cardRadius(double previous) =>
      roundedDepth ? previous * 1.25 : previous;
  static double cardDepth(double previous) =>
      roundedDepth ? previous * 1.5 : previous;
  static double outline(double previous) =>
      roundedDepth ? previous * 1.25 : previous;
}
