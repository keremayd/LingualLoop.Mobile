import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:provider/provider.dart';

/// Telaffuz butonu: hoparlör + ses dalgaları.
///
/// Karty'nin diğer kontrol glifleriyle (`karty_control_glyphs.dart`) aynı
/// aileden — tek renk, yuvarlak uçlu, kaplama gliflerinin dili. Üç renkli
/// "chunky sticker" reçetesi (§2.5) burada kullanılmadı: o reçete illüstrasyon
/// simgeleri için, bu ise renkli bir yüzeyin üstünde duran bir kontrol.
///
/// Depth-press (§2.4), uygulamadaki her basılabilir öğe gibi.
class PronunciationButton extends StatefulWidget {
  const PronunciationButton({
    super.key,
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  State<PronunciationButton> createState() => _PronunciationButtonState();
}

class _PronunciationButtonState extends State<PronunciationButton>
    with SingleTickerProviderStateMixin {
  /// Yüz ve taban **kaplama tonu**, renkli değil.
  ///
  /// Renk burada dar bir alandan seçiliyor çünkü ekranın renkleri dolu:
  ///   · `1CB1F5` = **der**, `F52A2A` = **die**, `FFB000` = **das**
  ///   · `93D334` = doğru cevap ve birincil eylem (ANLADIM)
  ///
  /// Buton kelimenin **yanında** durduğu için accent mavi felaket olurdu:
  /// artikel hapının bitişiğinde ikinci bir mavi nesne, bilinçaltında
  /// "mavi = der" eşlemesi kurardı — üstelik hap kırmızı `die` gösterirken.
  ///
  /// Kaplama tonu aynı zamanda **doğru sınıfı** söylüyor: telaffuz bir cevap
  /// değil, duraklat gibi bir yardımcı kontrol. İkili `163258` / `0B2143`
  /// pause butonuyla aynı — sayfa zemininde okunduğu ölçülmüş bir çift.
  static const _face = Color(0xFF163258);
  static const _depth = Color(0xFF0B2143);

  bool _isPressed = false;

  /// Ses dalgalarının döngüsü. Ses çaldığı **sürece** tekrar ediyor,
  /// bittiğinde duruyor — süre sesin kendisinden geliyor.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  ValueNotifier<bool>? _isSpeaking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<PronunciationService>().isSpeaking;
    if (identical(notifier, _isSpeaking)) return;
    _isSpeaking?.removeListener(_handleSpeakingChanged);
    _isSpeaking = notifier..addListener(_handleSpeakingChanged);
    _handleSpeakingChanged();
  }

  void _handleSpeakingChanged() {
    if (!mounted) return;
    if (_isSpeaking?.value == true) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _isSpeaking?.removeListener(_handleSpeakingChanged);
    _pulse.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  // Animasyon **burada** başlatılmıyor: dokunuş sesi tetikliyor, ses de
  // `isSpeaking` üzerinden animasyonu. Böylece otomatik çalmada da
  // (tanışma kartı açılışı, cevap sonrası) hoparlör oynuyor ve hareket
  // sesin gerçek süresi kadar sürüyor.

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: context.read<PronunciationService>().isMuted,
        builder: (context, muted, child) => Semantics(
          button: true,
          enabled: !muted,
          label: muted ? 'Telaffuz kapalı' : 'Kelimeyi dinle',
          child: _buildButton(context, muted),
        ),
      );

  Widget _buildButton(BuildContext context, bool muted) {
    final scale = widget.scale;
    final size = 96 * scale;
    final geometry = AppButtonStyle.resolve(
      width: size,
      totalHeight: 106 * scale,
      legacyRadius: 26 * scale,
      legacyDepth: 10 * scale,
    );
    final radius = geometry.radius;
    final shadowOffset = geometry.depth;

    return GestureDetector(
      onTap: muted ? null : widget.onTap,
      onTapDown: muted ? null : (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: SizedBox(
        width: size,
        height: 106 * scale,
        child: Stack(
          children: [
            Positioned(
              top: shadowOffset,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 60),
                opacity: _isPressed ? 0 : 1,
                child: Container(
                  height: geometry.faceHeight,
                  decoration: BoxDecoration(
                    color: _depth,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              top: _isPressed ? shadowOffset : 0,
              left: 0,
              right: 0,
              child: Container(
                height: geometry.faceHeight,
                decoration: BoxDecoration(
                  color: _face,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => SpeakerMark(
                      size: 52 * scale,
                      muted: muted,
                      wave: _pulse.value,
                      color: muted ? const Color(0xFF8FA0B5) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
