import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';

/// A persistent sound toggle, available even while the quiz is paused.
class KartySoundButton extends StatelessWidget {
  const KartySoundButton(
      {super.key,
      required this.scale,
      required this.muted,
      required this.onToggle});

  final double scale;
  final bool muted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final size = math.max(44.0, 84.75 * scale);
    return Semantics(
      label: muted ? 'Telaffuz sesi kapalı' : 'Telaffuz sesi açık',
      hint: muted ? 'Sesi aç' : 'Sesi kapat',
      toggled: !muted,
      child: Tooltip(
        message: muted ? 'Sesi aç' : 'Sesi kapat',
        child: DepthPressableButton(
          width: size,
          height: size - 3.125 * scale,
          radius: 24 * scale,
          shadowOffset: 8 * scale,
          backgroundColor: const Color(0xFF163258),
          shadowColor: const Color(0xFF0B2143),
          fontSize: 24 * scale,
          onPressed: onToggle,
          child: SpeakerMark(
              size: 50.25 * scale,
              muted: muted,
              color: muted ? const Color(0xFF8FA0B5) : const Color(0xFFE9EEF5)),
        ),
      ),
    );
  }
}
