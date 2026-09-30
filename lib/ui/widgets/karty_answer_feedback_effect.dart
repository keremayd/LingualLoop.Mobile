import 'package:lingualloop/ui/app_typography.dart';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/pronunciation_button.dart';

class KartyFeedbackWord extends StatefulWidget {
  const KartyFeedbackWord({
    super.key,
    required this.article,
    required this.text,
    required this.scale,
    required this.isCorrectActive,
    required this.isWrongActive,
    this.onPronounce,
  });

  final String article;
  final String text;
  final double scale;
  final ValueListenable<bool> isCorrectActive;
  final ValueListenable<bool> isWrongActive;

  /// Telaffuz butonunun eylemi. `null` ise buton çizilmiyor.
  ///
  /// Buton **kelimenin yanında** duruyor çünkü telaffuz karta değil kelimeye
  /// ait. Bir dönem kartla "ANLADIM" arasında tek başına duruyordu ve
  /// hiçbir şeye ait olmayan öksüz bir öğe gibi okunuyordu.
  final VoidCallback? onPronounce;

  @override
  State<KartyFeedbackWord> createState() => _KartyFeedbackWordState();
}

class _KartyFeedbackWordState extends State<KartyFeedbackWord>
    with TickerProviderStateMixin {
  late final AnimationController _correctController;
  late final AnimationController _wrongController;

  @override
  void initState() {
    super.initState();
    _correctController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    widget.isCorrectActive.addListener(_handleCorrectState);
    widget.isWrongActive.addListener(_handleWrongState);
  }

  void _handleCorrectState() {
    widget.isCorrectActive.value
        ? _correctController.forward(from: 0)
        : _correctController.reset();
  }

  void _handleWrongState() {
    widget.isWrongActive.value
        ? _wrongController.forward(from: 0)
        : _wrongController.reset();
  }

  @override
  void didUpdateWidget(covariant KartyFeedbackWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCorrectActive != widget.isCorrectActive) {
      oldWidget.isCorrectActive.removeListener(_handleCorrectState);
      widget.isCorrectActive.addListener(_handleCorrectState);
    }
    if (oldWidget.isWrongActive != widget.isWrongActive) {
      oldWidget.isWrongActive.removeListener(_handleWrongState);
      widget.isWrongActive.addListener(_handleWrongState);
    }
  }

  @override
  void dispose() {
    widget.isCorrectActive.removeListener(_handleCorrectState);
    widget.isWrongActive.removeListener(_handleWrongState);
    _correctController.dispose();
    _wrongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_correctController, _wrongController]),
      builder: (context, child) {
        final correct = _correctController.value;
        final wrong = _wrongController.value;
        final correctEnvelope = math.sin(correct * math.pi).clamp(0.0, 1.0);
        final wrongEnvelope = math.sin(wrong * math.pi).clamp(0.0, 1.0);
        final shake =
            math.sin(wrong * math.pi * 10) * 7 * widget.scale * wrongEnvelope;
        final nounColor = wrongEnvelope > 0
            ? Color.lerp(
                const Color(0xFFE9EEF5),
                // Paletin kırmızısından türetilmiş yumuşak ton.
                Color.lerp(
                    const Color(0xFFE9EEF5), const Color(0xFFF52A2A), 0.62)!,
                wrongEnvelope * 0.85,
              )!
            : Color.lerp(
                const Color(0xFFE9EEF5),
                const Color(0xFF93D334),
                correctEnvelope,
              )!;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: 1 + correctEnvelope * 0.035 - wrongEnvelope * 0.018,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.article.trim().isNotEmpty) ...[
                  _KartyArticleBadge(
                    article: widget.article,
                    scale: widget.scale,
                  ),
                  SizedBox(width: 21 * widget.scale),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: _textStyle.copyWith(color: nounColor),
                    ),
                  ),
                ),
                if (widget.onPronounce != null) ...[
                  SizedBox(width: 13 * widget.scale),
                  PronunciationButton(
                    // Ölçü **dokunma hedefinden** geliyor, optik
                    // dengeden değil. Buton gövdesi 96 birim; 0.84
                    // katsayısı 80 birim ≈ 46pt eder ve 44pt sınırının
                    // üstünde kalır.
                    //
                    // Bir tur 0.66 denendi (63 birim ≈ 36pt): kelimeyle
                    // orantısı hoştu ama basması zordu. Küçük bir
                    // kontrolü "daha zarif" diye sınırın altına indirmek
                    // erişilebilirlik borcudur.
                    scale: widget.scale * 0.84,
                    onTap: widget.onPronounce!,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle get _textStyle => TextStyle(
        color: Colors.white,
        fontSize: 88.5 * widget.scale,
        fontWeight: AppTypography.word,
        fontFamily: AppTypography.family,
        height: 1.1,
        letterSpacing: -0.9 * widget.scale,
      );
}

/// Approved article pill: 4.6 cqw type, 1.8/2.3 cqw padding, 1 cqw depth.
class _KartyArticleBadge extends StatelessWidget {
  const _KartyArticleBadge({
    required this.article,
    required this.scale,
  });

  final String article;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final (face, base) = _tonesFor(article);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 17.25 * scale, vertical: 13.5 * scale),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [BoxShadow(color: base, offset: Offset(0, 7.5 * scale))],
      ),
      child: Text(article.trim(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 34.5 * scale,
            fontWeight: AppTypography.label,
            fontFamily: AppTypography.family,
            height: 1.2,
          )),
    );
  }

  /// Yüz ve taban tonları; pusuladaki değerlerin birebir aynısı
  /// (`article_practice_screen.dart`).
  (Color, Color) _tonesFor(String article) {
    return switch (article.trim().toLowerCase()) {
      'der' => (const Color(0xFF1CB1F5), const Color(0xFF1B84B5)),
      'die' => (const Color(0xFFF52A2A), const Color(0xFFAA1C1C)),
      'das' => (const Color(0xFFFFB000), const Color(0xFFC97800)),
      // Beyaz yüz + beyaz metin okunmaz; bilinmeyen artikel sönük griye
      // düşüyor.
      _ => (const Color(0xFF8FA0B5), const Color(0xFF5A6B80)),
    };
  }
}

class KartyCardFeedbackEffect extends StatefulWidget {
  const KartyCardFeedbackEffect({
    super.key,
    required this.scale,
    required this.isWrongActive,
  });

  final double scale;
  final ValueListenable<bool> isWrongActive;

  @override
  State<KartyCardFeedbackEffect> createState() =>
      _KartyCardFeedbackEffectState();
}

class _KartyCardFeedbackEffectState extends State<KartyCardFeedbackEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wrongController;

  @override
  void initState() {
    super.initState();
    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    widget.isWrongActive.addListener(_handleWrongState);
  }

  void _handleWrongState() {
    widget.isWrongActive.value
        ? _wrongController.forward(from: 0)
        : _wrongController.reset();
  }

  @override
  void didUpdateWidget(covariant KartyCardFeedbackEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWrongActive != widget.isWrongActive) {
      oldWidget.isWrongActive.removeListener(_handleWrongState);
      widget.isWrongActive.addListener(_handleWrongState);
    }
  }

  @override
  void dispose() {
    widget.isWrongActive.removeListener(_handleWrongState);
    _wrongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _wrongController,
          builder: (context, child) {
            if (_wrongController.value == 0) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _KartyCardFeedbackPainter(
                wrongProgress: _wrongController.value,
                scale: widget.scale,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _KartyCardFeedbackPainter extends CustomPainter {
  const _KartyCardFeedbackPainter({
    required this.wrongProgress,
    required this.scale,
  });

  final double wrongProgress;
  final double scale;

  static const _wrongRed = Color(0xFFFF4D3D);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final inset = 3 * scale;
    final rimRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rimPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rimRect, Radius.circular(56 * scale)),
      );
    final metric = rimPath.computeMetrics().first;

    if (wrongProgress > 0) {
      _drawWrongDrain(canvas, size, rimPath, metric);
    }
  }

  void _drawWrongDrain(
    Canvas canvas,
    Size size,
    Path rimPath,
    PathMetric metric,
  ) {
    final strike = math.sin(
      (wrongProgress / 0.42).clamp(0.0, 1.0) * math.pi,
    );
    final fade = 1 -
        Curves.easeInCubic.transform(
          ((wrongProgress - 0.62) / 0.38).clamp(0.0, 1.0),
        );

    canvas.drawPath(
      rimPath,
      Paint()
        // Kenardaki kırmızı halka **kısıldı**. Yanlış cevapta dört sinyal
        // aynı anda çalışıyordu: kart sarsılıyor, çerçeve kızarıyor, kart
        // küçülüyor ve kenar kırmızı yanıyordu. Küçülme kaldırıldı,
        // kızarma yumuşadı; bu halka da alarm olmaktan çıkıp eşlik eden bir
        // ipucuna indi.
        // Yanlış cevabın **tek görsel işareti**: kartı saran kırmızı hale.
        //
        // Doz kalibre edildi. 0.16 koyu zeminde tamamen kayboluyordu, 0.70
        // ise alarm gibiydi; 0.38 okunuyor ama azarlamıyor. Genişlik 16
        // birim — 22'de hale kartı yutuyordu.
        ..color = _wrongRed.withValues(alpha: 0.38 * strike * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * scale
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale),
    );
    // ## Buradan iki sinyal **kaldırıldı**
    //
    // 1. Dönen `SweepGradient` halkası (alfa 0.88) — kartın çevresinde
    //    turuncu bir çember yakıyordu. İkinci bir alarmdı ve §2.2 gradyan
    //    bulanıklığını zaten yasaklıyor.
    // 2. Kenardan dışarı uçan 11 "enerji damlacığı" — kart hasar almış,
    //    parçalanmış gibi okunuyordu.
    //
    // Yanlış cevapta toplam **altı** sinyal aynı anda çalışıyordu: sarsıntı,
    // çerçevenin kızarması, kartın küçülmesi, bulanık kırmızı halka, dönen
    // halka ve parçacıklar. Hepsi birden "cezalandırıldın" diyordu.
    //
    // Kalanlar: kısa bir "hayır" jesti, çerçevede hafif kızarma ve kenarda
    // çok sönük bir kırmızı iz. Bilgilendiren kısım — doğru yazımın
    // yukarıda belirmesi — zaten ayrı bir katman ve o dokunulmadı.
  }

  @override
  bool shouldRepaint(covariant _KartyCardFeedbackPainter oldDelegate) {
    return oldDelegate.wrongProgress != wrongProgress ||
        oldDelegate.scale != scale;
  }
}
