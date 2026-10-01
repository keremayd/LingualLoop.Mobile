import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';

/// Duraklatmada da erişilen ses tercihi; dalgalar gerçek telaffuzu izler.
class KartySoundButton extends StatefulWidget {
  const KartySoundButton(
      {super.key,
      required this.scale,
      required this.muted,
      this.speaking = false,
      required this.onToggle});

  final double scale;
  final bool muted;
  final bool speaking;
  final VoidCallback onToggle;

  @override
  State<KartySoundButton> createState() => _KartySoundButtonState();
}

class _KartySoundButtonState extends State<KartySoundButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 620));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncWave();
  }

  @override
  void didUpdateWidget(covariant KartySoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWave();
  }

  void _syncWave() {
    if (widget.speaking && !widget.muted && !_reduceMotion) {
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      _wave.stop();
      _wave.value = 0;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final muted = widget.muted;
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
          onPressed: widget.onToggle,
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, child) => SpeakerMark(
                wave: _reduceMotion && widget.speaking && !muted
                    ? 0.5
                    : _wave.value,
                size: 50.25 * scale,
                muted: muted,
                color:
                    muted ? const Color(0xFF8FA0B5) : const Color(0xFFE9EEF5)),
          ),
        ),
      ),
    );
  }
}
