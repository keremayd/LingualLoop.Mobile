import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_card_material.dart';
import 'package:lingualloop/ui/widgets/surface_gloss.dart';

/// Görsel seçilen sorularda soruyu taşıyan yatay kart.
///
/// Büyük kartla aynı malzeme: lacivert yüz, üst kenarda cam parlaması,
/// altında deste, köşelerinde boost şimşekleri. Kural her soru tipinde aynı:
/// kart soruyu taşır, cevaplar kartın altındaki düğmelerdir.
class KartyQuestionCard extends StatelessWidget {
  const KartyQuestionCard({
    super.key,
    required this.scale,
    required this.width,
    required this.isCorrectActive,
    required this.isWrongActive,
    required this.child,
    this.boostMeter,
    this.dimmed = false,
  });

  /// Kartın yüksekliği ve destenin kayması (tasarım birimi).
  static const cardHeight = 380.0;
  static const layerOffset = 20.0;

  /// Kartın, destesinin ve kalınlık bandının toplam yüksekliği.
  static double extentFor(double scale) =>
      (cardHeight + 2 * layerOffset + KartyCardMaterial.depth) * scale;

  final double scale;
  final double width;
  final ValueListenable<bool> isCorrectActive;
  final ValueListenable<bool> isWrongActive;
  final Widget child;
  final Widget? boostMeter;

  /// Süre dolunca kart söner.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final height = cardHeight * s;
    final offset = layerOffset * s;
    final depth = KartyCardMaterial.depth * s;
    final radius = BorderRadius.circular(52.5 * s);

    Widget layer(int level, Color face, Color edge) => Positioned(
          top: offset * level,
          child: Container(
            width: width * (1 - .05 * level),
            height: height,
            decoration: BoxDecoration(
              color: face,
              borderRadius: radius,
              boxShadow: [BoxShadow(color: edge, offset: Offset(0, depth))],
            ),
          ),
        );

    return SizedBox(
      width: width,
      height: extentFor(s),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          layer(2, KartyCardMaterial.face, KartyCardMaterial.base),
          layer(1, KartyCardMaterial.face, KartyCardMaterial.base),
          Positioned(
            top: 0,
            left: 0,
            width: width,
            height: height,
            child: KartyCardFeedbackEffect(
              scale: s,
              isWrongActive: isWrongActive,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: width,
            height: height,
            // Doğru cevapta büyük kartta olduğu gibi yalnız alt bant yeşerir.
            child: ValueListenableBuilder<bool>(
              valueListenable: isCorrectActive,
              builder: (context, correct, face) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: dimmed
                      ? KartyCardMaterial.dimFace
                      : KartyCardMaterial.face,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: dimmed
                          ? KartyCardMaterial.dimBase
                          : correct
                              ? KartyCardMaterial.correctBase
                              : KartyCardMaterial.base,
                      offset: Offset(0, depth),
                    ),
                  ],
                ),
                child: face,
              ),
              child: CustomPaint(
                painter: TopRimPainter(
                  color: KartyCardMaterial.rim,
                  radius: 52.5 * s,
                  strokeWidth: AppShapeStyle.outline(3 * s),
                ),
                child: Padding(
                  padding: EdgeInsets.all(23.25 * s),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 26 * s),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          if (boostMeter != null)
            Positioned(
              top: 0,
              left: 0,
              width: width,
              height: height,
              child: boostMeter!,
            ),
        ],
      ),
    );
  }
}
