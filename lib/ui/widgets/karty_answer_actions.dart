import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';

/// Ok bir gliftir; metin fontunun sembol kapsamına bağlı kalmaz.
class KartyDebugAnswerLabel extends StatelessWidget {
  const KartyDebugAnswerLabel({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TEST · DOĞRU',
              style: TextStyle(
                  fontFamily: AppTypography.family,
                  fontWeight: AppTypography.label,
                  fontSize: 22.5 * scale)),
          SizedBox(width: 6 * scale),
          Icon(Icons.arrow_forward_rounded, size: 22.5 * scale),
        ],
      );
}

/// Her durumda aynı alt yuva: iki cevap veya tek ilerleme eylemi.
class KartyAnswerActions extends StatelessWidget {
  const KartyAnswerActions({
    super.key,
    required this.scale,
    required this.onWrong,
    required this.onCorrect,
    required this.onContinue,
    this.isIntroducing = false,
    this.isTimedOut = false,
    this.enabled = true,
  });

  final double scale;
  final bool isIntroducing;
  final bool isTimedOut;
  final bool enabled;
  final VoidCallback onWrong;
  final VoidCallback onCorrect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          Widget button({
            required double width,
            required String label,
            required Color face,
            required Color depth,
            required VoidCallback onTap,
            KartyControlGlyph? glyph,
          }) =>
              Semantics(
                label: label,
                child: DepthPressableButton(
                  width: width,
                  height: 119.25 * scale,
                  radius: 34 * scale,
                  shadowOffset: 12 * scale,
                  backgroundColor: face,
                  shadowColor: depth,
                  fontSize: 28 * scale,
                  enabled: enabled,
                  onPressed: onTap,
                  child: ExcludeSemantics(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (glyph != null) ...[
                            KartyControlMark(glyph: glyph, size: 51 * scale),
                            SizedBox(width: 20.25 * scale),
                          ],
                          Text(label,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: AppTypography.family,
                                  fontSize:
                                      (glyph == null ? 33.75 : 26.25) * scale,
                                  fontWeight: AppTypography.action)),
                        ]),
                  ),
                ),
              );
          if (isIntroducing || isTimedOut) {
            return button(
                width: constraints.maxWidth,
                label: isIntroducing ? 'ANLADIM' : 'TEKRAR DENE',
                face: const Color(0xFF1CB1F5),
                depth: const Color(0xFF1B84B5),
                onTap: onContinue);
          }
          final gap = 37.5 * scale;
          final width = (constraints.maxWidth - gap) / 2;
          return Row(children: [
            button(
                width: width,
                label: 'YANLIŞ',
                glyph: KartyControlGlyph.cross,
                face: const Color(0xFFF52A2A),
                depth: const Color(0xFF9A1414),
                onTap: onWrong),
            SizedBox(width: gap),
            button(
                width: width,
                label: 'DOĞRU',
                glyph: KartyControlGlyph.check,
                face: const Color(0xFF93D334),
                depth: const Color(0xFF628C22),
                onTap: onCorrect),
          ]);
        },
      );
}
