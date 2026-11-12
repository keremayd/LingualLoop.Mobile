import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';
import 'package:provider/provider.dart';

/// Dinleme sorusunun soru kartındaki içerik: sesli mesaj gibi bir hap ve
/// altında yavaş çalma düğmesi (11 Kas 2026, kullanıcı onayı).
///
/// Kartın ortasında tek başına duran büyük hoparlör ne basılabilir
/// görünüyordu ne de çaldığını belli ediyordu. Hapın tamamı dokunuşu alır,
/// içindeki hoparlör düğmesi basılır; ses çaldıkça çubuklar soldan sağa
/// dolar, yavaş çalmada daha ağır dolar. Düğme mavi değil: mavi der'in rengi
/// (bkz. `PronunciationButton`). Yavaş düğmesinde yazı değil salyangoz var.
class KartyListenPlayer extends StatefulWidget {
  const KartyListenPlayer({
    super.key,
    required this.scale,
    required this.onListen,
    required this.onListenSlowly,
  });

  final double scale;
  final VoidCallback onListen;
  final VoidCallback onListenSlowly;

  @override
  State<KartyListenPlayer> createState() => _KartyListenPlayerState();
}

class _KartyListenPlayerState extends State<KartyListenPlayer>
    with TickerProviderStateMixin {
  static const _pill = Color(0xFF0C2244);
  static const _slowFace = Color(0xFF0C2244);
  static const _slowDepth = Color(0xFF07182F);

  /// Hoparlör dalgalarının döngüsü; telaffuz düğmesiyle aynı tempo.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// Çubukların dolumu; süresi her çalmada sesin kendisinden gelir.
  late final AnimationController _progress = AnimationController(vsync: this);

  PronunciationService? _audio;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = context.read<PronunciationService>();
    if (identical(audio, _audio)) return;
    _audio?.isSpeaking.removeListener(_handleSpeakingChanged);
    _audio = audio..isSpeaking.addListener(_handleSpeakingChanged);
    _handleSpeakingChanged();
  }

  void _handleSpeakingChanged() {
    final audio = _audio;
    if (!mounted || audio == null) return;
    if (audio.isSpeaking.value) {
      if (!_pulse.isAnimating) _pulse.repeat();
      _progress
        ..duration = audio.playbackLength ?? const Duration(milliseconds: 900)
        ..forward(from: 0);
    } else {
      _pulse
        ..stop()
        ..value = 0;
      _progress
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _audio?.isSpeaking.removeListener(_handleSpeakingChanged);
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    // Hap da uygulamanın yuvarlatılmış dikdörtgeni, tam yuvarlak değil
    // (kullanıcı). Köşesi içindeki hoparlör düğmesininkiyle eş merkezli:
    // düğmenin köşesi + aradaki pay; iki köşe aynı kavisi izler.
    final pillHeight = 128 * s;
    final pillRadius = _SpeakerKey.geometryFor(s).radius +
        (pillHeight - _SpeakerKey.totalHeight * s) / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Kelimeyi dinle',
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('karty-listen'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onListen,
            child: Container(
              width: 392 * s,
              height: pillHeight,
              padding: EdgeInsets.only(left: 18 * s, right: 26 * s),
              decoration: BoxDecoration(
                color: _pill,
                borderRadius: BorderRadius.circular(pillRadius),
              ),
              child: Row(
                children: [
                  _SpeakerKey(scale: s, pressed: _pressed, wave: _pulse),
                  SizedBox(width: 20 * s),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => CustomPaint(
                        size: Size.fromHeight(70 * s),
                        painter: _WaveBarsPainter(played: _progress.value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 26 * s),
        Semantics(
          button: true,
          label: 'Yavaş dinle',
          excludeSemantics: true,
          child: DepthPressableButton(
            key: const ValueKey('karty-listen-slow'),
            width: 96 * s,
            height: 84 * s,
            radius: 26 * s,
            shadowOffset: 10 * s,
            backgroundColor: _slowFace,
            shadowColor: _slowDepth,
            fontSize: 0,
            onPressed: widget.onListenSlowly,
            child: KartyControlMark(
              glyph: KartyControlGlyph.slow,
              size: 58 * s,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hapın içindeki hoparlör düğmesi: uygulamanın düğme geometrisi (köşe ve
/// alt bant `AppButtonStyle`'dan), beyaz yüz, lacivert simge. Basılma
/// hapın dokunuşundan gelir; çökme §2.4'teki gibi alt banda.
class _SpeakerKey extends StatelessWidget {
  const _SpeakerKey({
    required this.scale,
    required this.pressed,
    required this.wave,
  });

  static const _face = Color(0xFFE9EEF5);
  static const _depth = Color(0xFFBDC5D0);
  static const _glyph = Color(0xFF163258);

  /// Yüz + alt bant, tasarım biriminde.
  static const width = 92.0;
  static const totalHeight = 98.0;

  static AppButtonGeometry geometryFor(double scale) => AppButtonStyle.resolve(
        width: width * scale,
        totalHeight: totalHeight * scale,
        legacyRadius: 26 * scale,
        legacyDepth: 10 * scale,
        icon: true,
      );

  final double scale;
  final bool pressed;
  final Animation<double> wave;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final geometry = geometryFor(s);
    final radius = BorderRadius.circular(geometry.radius);
    return SizedBox(
      width: width * s,
      height: totalHeight * s,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: geometry.depth,
            height: geometry.faceHeight,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 60),
              opacity: pressed ? 0 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: _depth, borderRadius: radius),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: pressed ? geometry.depth : 0,
            height: geometry.faceHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(color: _face, borderRadius: radius),
              child: Center(
                child: AnimatedBuilder(
                  animation: wave,
                  builder: (context, _) => SpeakerMark(
                    size: 50 * s,
                    wave: wave.value,
                    color: _glyph,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sesli mesajın dalgası: sabit, doğal görünen bir biçim; `played` kadarı tam
/// beyaz, kalanı soluk. Biçim kelimeye göre değişmez, uzunluk ipucu vermesin.
class _WaveBarsPainter extends CustomPainter {
  const _WaveBarsPainter({required this.played});

  final double played;

  static const _heights = [
    .30, .48, .72, .94, .62, .40, .58, .86, //
    1.0, .74, .50, .66, .88, .56, .36, .26,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _heights.length;
    final width = step * .56;
    for (final (index, height) in _heights.indexed) {
      final bar = Rect.fromCenter(
        center: Offset(step * (index + .5), size.height / 2),
        width: width,
        height: math.max(width, height * size.height),
      );
      final on = (index + .5) / _heights.length <= played;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(width / 2)),
        Paint()..color = Colors.white.withValues(alpha: on ? 1 : .28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveBarsPainter oldDelegate) =>
      oldDelegate.played != played;
}
