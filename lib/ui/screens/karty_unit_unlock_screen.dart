import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';

/// Karty Yolu'nda yeni bir ünitenin açıldığı an.
///
/// Anı **patikadaki nesneyle** anlatır: ünitenin 3B simgesi patikadaki
/// kilitli hâliyle (lacivert silüet + gri kilit) gelir; kilit sallanır,
/// kancası kalkar ve düşer, renk kilidin asılı olduğu yerden yayılır, arkada
/// görev ödülündeki krem ışık açılır. Kullanıcı patikaya döndüğünde aynı
/// nesneyi ünite başlığında açık hâliyle görür.
///
/// Lig atlama sahnesinin kalıbı: oyundan sonra tam ekran açılır, geri tuşu
/// kapalıdır; tek eylem DEVAM ET sunucuya gördüğünü bildirir. Bildirim
/// düşerse ekran kapanmaz, kullanıcı yeniden dener.
class KartyUnitUnlockScreen extends StatefulWidget {
  const KartyUnitUnlockScreen({
    super.key,
    required this.unlock,
    required this.onContinue,
  });

  final KartyUnitUnlock unlock;
  final Future<bool> Function() onContinue;

  @override
  State<KartyUnitUnlockScreen> createState() => _KartyUnitUnlockScreenState();
}

class _KartyUnitUnlockScreenState extends State<KartyUnitUnlockScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;

  /// Işık bu sürede bir dilim döner; on katlı simetri sayesinde döngü
  /// dikişsiz kapanır. Nesnenin süzülmesi de aynı döngüde (tam sayı frekans,
  /// §4.4).
  late final AnimationController _idle;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hareket azaltılmışsa sahne doğrudan son hâliyle açılır.
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_entrance.value < 1 || _submitting) return;
    setState(() => _submitting = true);

    var acknowledged = false;
    try {
      acknowledged = await widget.onContinue();
    } catch (_) {
      acknowledged = false;
    }

    if (!mounted) return;
    if (acknowledged) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Ünite bilgisi kaydedilemedi. Tekrar dene.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_entrance, _idle]),
            builder: (context, _) => KartyUnitUnlockScene(
              unlock: widget.unlock,
              progress: _entrance.value,
              idle: _idle.value,
              submitting: _submitting,
              onContinue: _continue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sahnenin kendisi; zamanı dışarıdan alır ki önizleme her kareyi
/// çizebilsin. [progress] giriş zaman çizelgesi (0–1), [idle] bekleme
/// döngüsü (0–1).
class KartyUnitUnlockScene extends StatelessWidget {
  const KartyUnitUnlockScene({
    super.key,
    required this.unlock,
    required this.progress,
    this.idle = 0,
    this.submitting = false,
    this.onContinue,
  });

  final KartyUnitUnlock unlock;
  final double progress;
  final double idle;
  final bool submitting;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final unit = unlock.unlocked;
    final t = progress;

    return ColoredBox(
      color: _C.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth / 750;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: KartyStarfieldPainter(scale: s)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  40 * s,
                  padding.top,
                  40 * s,
                  padding.bottom + 40 * s,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _UnlockHero(
                        unit: unit,
                        scale: s,
                        progress: t,
                        idle: idle,
                      ),
                    ),
                    _Rise(
                      progress: _phase(t, 0.62, 0.82, Curves.easeOutCubic),
                      distance: 36 * s,
                      child: Text(
                        'ÜNİTE ${unit.number} AÇILDI',
                        style: TextStyle(
                          color: _C.accent,
                          fontSize: 26 * s,
                          fontWeight: AppTypography.number,
                          fontFamily: AppTypography.family,
                          letterSpacing: 3 * s,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    _Rise(
                      progress: _phase(t, 0.66, 0.86, Curves.easeOutCubic),
                      distance: 36 * s,
                      // Uzun ünite adı kesilmez, sığacak kadar küçülür
                      // (ünite başlığındaki kuralın aynısı, §2.11).
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          unit.title,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 88 * s,
                            fontWeight: AppTypography.heading,
                            fontFamily: AppTypography.displayFamily,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18 * s),
                    _Rise(
                      progress: _phase(t, 0.70, 0.90, Curves.easeOutCubic),
                      distance: 36 * s,
                      child: Text(
                        '${unlock.reason}\n'
                        '${unit.wordCount} yeni kelime seni bekliyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _C.muted,
                          fontSize: 30 * s,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 64 * s),
                    _Rise(
                      progress: _phase(t, 0.82, 1, Curves.easeOutCubic),
                      distance: 40 * s,
                      child: SizedBox(
                        height: 124 * s,
                        child: submitting
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: _C.green,
                                ),
                              )
                            : DepthPressableButton(
                                key: const Key('karty-unit-unlock-continue'),
                                text: 'DEVAM ET',
                                width: 670 * s,
                                height: 112 * s,
                                radius: 26 * s,
                                shadowOffset: 12 * s,
                                backgroundColor: _C.green,
                                shadowColor: _C.greenDepth,
                                fontSize: 32 * s,
                                enabled: t >= 1 && onContinue != null,
                                onPressed: onContinue ?? () {},
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

abstract final class _C {
  static const bg = Color(0xFF041227);
  static const raised = Color(0xFF163258);
  static const accent = Color(0xFF1CB1F5);
  static const green = Color(0xFF93D334);
  static const greenDepth = Color(0xFF628C22);
  static const muted = Color(0xFF8FA0B5);
}

double _phase(double t, double begin, double end,
        [Curve curve = Curves.linear]) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Nesne, kilidi, ışığı ve açılma anının halkası ile kıvılcımları.
///
/// Zaman çizelgesi (giriş 0–1):
///
/// | Aralık | Ne olur |
/// |---|---|
/// | 0.00–0.18 | Kilitli nesne gelir (silüet + kilit) |
/// | 0.18–0.40 | Kilit sallanır — açılmadan önceki bekleyiş |
/// | 0.40–0.50 | Kanca kalkar |
/// | 0.50–0.70 | Kilit düşer; renk kilidin yerinden yayılır, nesne zıplar |
/// | 0.52–0.80 | Işık açılır, halka genişleyip söner |
class _UnlockHero extends StatelessWidget {
  const _UnlockHero({
    required this.unit,
    required this.scale,
    required this.progress,
    required this.idle,
  });

  final KartyUnit unit;
  final double scale;
  final double progress;
  final double idle;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = progress;
    final appear = _phase(t, 0, 0.18, Curves.easeOutBack);
    final shake = _phase(t, 0.18, 0.40);
    final shackle = _phase(t, 0.40, 0.50, Curves.easeOutCubic);
    final fall = _phase(t, 0.50, 0.70, Curves.easeInCubic);
    final reveal = _phase(t, 0.50, 0.68, Curves.easeOutCubic);
    final pop = _phase(t, 0.50, 0.74);
    final light = _phase(t, 0.52, 0.80, Curves.easeOutCubic);
    final ring = _phase(t, 0.52, 0.82, Curves.easeOutCubic);
    final sparkle = _phase(t, 0.54, 0.84);
    final fade = appear.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(460 * s, constraints.maxHeight * 0.66);
        // Işık nesneye ait: nesne süzülürken ışığı da onunla gider (§5,
        // görev ödülündeki hâle dersi).
        final hover = math.sin(idle * 2 * math.pi) * 8 * s * light;
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight * 0.60 + hover,
        );
        final box = Rect.fromCenter(center: center, width: size, height: size);
        // Kilit nesnenin ortasına asılı; renk oradan yayılır.
        final lockAnchor = Offset(size / 2, size * 0.58);
        final lockSize = size * 0.42;
        final emblemScale =
            (0.82 + 0.18 * appear) * (1 + 0.10 * math.sin(math.pi * pop));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: center.dx - size * 0.82,
              top: center.dy - size * 0.82,
              child: IgnorePointer(
                // Reçete oranı: ışık, öznenin görünen yarıçapının ~2.6 katında
                // söner (görev ödülünde 285 / 110). Nesne kutusunun ~%65'ini
                // doldurduğu için kutu boyunun 0.82'si.
                child: CelebrationLightRays(
                  reach: size * 0.82,
                  open: light,
                  drift: idle * 2 * math.pi / 10,
                ),
              ),
            ),
            if (ring > 0 && ring < 1)
              Positioned(
                left: center.dx - size,
                top: center.dy - size,
                child: IgnorePointer(
                  child: KartyUnlockRing(
                    progress: ring,
                    radius: size / 2,
                    scale: s,
                  ),
                ),
              ),
            Positioned.fromRect(
              rect: box,
              child: Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: emblemScale,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 1 - _phase(t, 0.62, 0.70),
                        child: _object(size, silhouette: true),
                      ),
                      ClipOval(
                        clipper: KartyCircleReveal(
                          center: lockAnchor,
                          radius: reveal * size * 0.95,
                        ),
                        child: _object(size, silhouette: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (sparkle > 0 && sparkle < 1)
              Positioned(
                left: center.dx - size,
                top: center.dy - size,
                child: IgnorePointer(
                  child: KartyUnlockSparkles(
                    progress: sparkle,
                    radius: size / 2,
                    scale: s,
                  ),
                ),
              ),
            if (fall < 1)
              Positioned(
                left: box.left + lockAnchor.dx - lockSize / 2,
                top: box.top + lockAnchor.dy - lockSize / 2 + fall * 240 * s,
                child: Opacity(
                  opacity: fade * (1 - fall),
                  child: Transform.rotate(
                    // Üç tam sallanma, sönerek; sonra düşerken devrilir.
                    angle: math.sin(shake * math.pi * 6) * 0.18 * (1 - shake) +
                        fall * 0.8,
                    child: Transform.scale(
                      scale: 1 + 0.10 * math.sin(math.pi * shackle),
                      child: KartyLockMark(size: lockSize, open: shackle),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _object(double size, {required bool silhouette}) {
    final image = unit.emblem;
    if (image != null) {
      return silhouette
          ? KartySilhouette(image: image, color: _C.raised, size: size)
          : KartyShadowedImage(image: image, size: size, scale: scale);
    }
    // Simgesi olmayan ünite: kitap (öğrenme), aynı silüet → renk dönüşümüyle.
    final icon = Center(
      child: QuestIcon(questKey: 'learn_three', size: size * 0.7),
    );
    return silhouette
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(_C.raised, BlendMode.srcIn),
            child: icon,
          )
        : icon;
  }
}

class _Rise extends StatelessWidget {
  const _Rise({
    required this.progress,
    required this.distance,
    required this.child,
  });

  final double progress;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * distance),
        child: child,
      ),
    );
  }
}
