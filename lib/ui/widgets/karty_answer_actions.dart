import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

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

/// Her durumda aynı alt yuva: artikel cevapları veya tek ilerleme eylemi.
class KartyAnswerActions extends StatelessWidget {
  const KartyAnswerActions({
    super.key,
    required this.scale,
    required this.onContinue,
    this.answers,
    this.isIntroducing = false,
    this.isTimedOut = false,
    this.enabled = true,
  });

  final double scale;
  final bool isIntroducing;
  final bool isTimedOut;
  final bool enabled;
  final VoidCallback onContinue;

  /// Soru bu yuvada cevaplanıyorsa cevap düğmeleri.
  final Widget? answers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (!isIntroducing && !isTimedOut) {
            return answers ?? const SizedBox.shrink();
          }
          final label = isIntroducing ? 'ANLADIM' : 'TEKRAR DENE';
          return Semantics(
            label: label,
            child: DepthPressableButton(
              width: constraints.maxWidth,
              height: 119.25 * scale,
              radius: 34 * scale,
              shadowOffset: 12 * scale,
              backgroundColor: const Color(0xFF1CB1F5),
              shadowColor: const Color(0xFF1B84B5),
              fontSize: 28 * scale,
              enabled: enabled,
              onPressed: onContinue,
              child: ExcludeSemantics(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTypography.family,
                        fontSize: 33.75 * scale,
                        fontWeight: AppTypography.action)),
              ),
            ),
          );
        },
      );
}
