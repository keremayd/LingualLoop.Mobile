import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/karty_unit_marks.dart';
import 'package:lingualloop/ui/widgets/pressable_layered_card.dart';

// Karty Yolu'nun ünite kartı. Patikada her ünitenin başlığı, oturum
// özetinde günün ilerlemesi bu kartla gösterilir; iki ayrı kart çizilseydi
// özetteki kartın patikadaki ünite olduğu anlaşılmazdı (§2.5 "tekrar eden
// simge tek bir yoldan gelir").

abstract final class _C {
  static const tile = Color(0xFF0C2244);
  static const raised = Color(0xFF163258);
  static const base = Color(0xFF07182F);
  static const accent = Color(0xFF1CB1F5);
  static const accentDepth = Color(0xFF1B84B5);
  static const muted = Color(0xFF8FA0B5);
  static const value = Color(0xFFE9EEF5);
}

double _phase(double t, double begin, double end,
        [Curve curve = Curves.linear]) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Ünite başlığı — ana ekrandaki Karty kartının dili: aynı mavi yüz,
/// aynı taban ve köşe, solda metin, sağda 3B ünite nesnesi. Kilitli ünitede
/// yüz lacivert, nesne siluet: ne geleceği belli, kendisi henüz kapalı.
class KartyUnitHeader extends StatelessWidget {
  const KartyUnitHeader({
    super.key,
    required this.unit,
    required this.scale,
    required this.onTap,
    this.arrival,
    this.consolidated,
  });

  final KartyUnit unit;
  final double scale;
  final VoidCallback onTap;

  /// Pekişen kelime sayısı yerine çizilecek değer (oturum özetinde çubuk
  /// eski değerden yenisine dolar); null ise ünitenin kendi sayısı.
  final double? consolidated;

  /// Yeni açılan ünitede kilitliden açığa geçiş (0–1); null ise başlık
  /// ünitenin kendi durumuyla çizilir. Kutlama ekranındaki hareketin
  /// aynısı: kilit sallanır, kancası kalkar ve düşer; açık yüz kilidin
  /// asılı olduğu yerden yayılır.
  final double? arrival;

  /// Yüz + taban, tasarım biriminde.
  static const height = 244.0;

  /// Köşe yarıçapı; [scale] tasarım biriminden ekrana çevirir.
  static double cornerRadius(double scale) =>
      AppButtonStyle.tileRadius(28 * scale);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(cornerRadius(s));
    final depth = AppButtonStyle.tileDepth(8 * s);
    final a = arrival;
    if (a == null) {
      final locked = unit.state == KartyUnitState.locked;
      return _card(
        radius: radius,
        depth: depth,
        base: locked ? _C.base : _C.accentDepth,
        face: _face(locked: locked, radius: radius),
      );
    }

    final shake = _phase(a, 0, 0.30);
    final shackle = _phase(a, 0.30, 0.44, Curves.easeOutCubic);
    final fall = _phase(a, 0.44, 0.72, Curves.easeInCubic);
    final reveal = _phase(a, 0.44, 0.70, Curves.easeOutCubic);
    final pop = _phase(a, 0.44, 0.80);
    final ring = _phase(a, 0.46, 0.90, Curves.easeOutCubic);
    final sparkle = _phase(a, 0.50, 0.96);
    // Kilit ünite nesnesinin üstünde: yüzün sağındaki görsel kutusunun ortası.
    final emblem = Offset((670 - 26 - 118) * s, (height * s - depth) / 2);
    final lockSize = 112 * s;
    final r = 107 * s;

    return SizedBox(
      width: 670 * s,
      height: height * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _card(
            radius: radius,
            depth: depth,
            base: Color.lerp(_C.base, _C.accentDepth, reveal)!,
            face: Stack(
              children: [
                _face(locked: true, radius: radius),
                ClipOval(
                  clipper: KartyCircleReveal(
                    center: emblem,
                    radius: reveal * 560 * s,
                  ),
                  child: _face(
                    locked: false,
                    radius: radius,
                    emblemScale: 1 + 0.12 * math.sin(math.pi * pop),
                  ),
                ),
              ],
            ),
          ),
          if (ring > 0 && ring < 1)
            Positioned(
              left: emblem.dx - 2 * r,
              top: emblem.dy - 2 * r,
              child: IgnorePointer(
                child: KartyUnlockRing(progress: ring, radius: r, scale: s),
              ),
            ),
          if (sparkle > 0 && sparkle < 1)
            Positioned(
              left: emblem.dx - 2 * r,
              top: emblem.dy - 2 * r,
              child: IgnorePointer(
                child: KartyUnlockSparkles(
                  progress: sparkle,
                  radius: r,
                  scale: s,
                ),
              ),
            ),
          if (fall < 1)
            Positioned(
              left: emblem.dx - lockSize / 2,
              top: emblem.dy - lockSize / 2 + fall * 200 * s,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 1 - fall,
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
            ),
        ],
      ),
    );
  }

  Widget _card({
    required BorderRadius radius,
    required double depth,
    required Color base,
    required Widget face,
  }) =>
      PressableLayeredCard(
        width: 670 * scale,
        height: height * scale,
        shadowOffset: depth,
        radius: radius,
        baseColor: base,
        onPressed: onTap,
        face: face,
      );

  Widget _face({
    required bool locked,
    required BorderRadius radius,
    double emblemScale = 1,
  }) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: locked ? _C.tile : _C.accent,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (unit.emblem != null)
            Positioned(
              right: 26 * s,
              top: 0,
              bottom: 0,
              width: 236 * s,
              child: Center(
                child: locked
                    ? KartySilhouette(
                        image: unit.emblem!,
                        size: 196 * s,
                        color: _C.raised,
                      )
                    : Transform.scale(
                        scale: emblemScale,
                        child: KartyShadowedImage(
                          image: unit.emblem!,
                          size: 214 * s,
                          scale: s,
                        ),
                      ),
              ),
            ),
          Positioned(
            left: 40 * s,
            top: 30 * s,
            right: 280 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÜNİTE ${unit.number}',
                  style: TextStyle(
                    color: locked
                        ? _C.muted
                        : Colors.white.withValues(alpha: 0.82),
                    fontSize: 23 * s,
                    fontWeight: AppTypography.number,
                    fontFamily: AppTypography.family,
                    letterSpacing: 1.6 * s,
                    height: 1,
                  ),
                ),
                SizedBox(height: 8 * s),
                // Uzun ünite adı kesilmez, sığacak kadar küçülür
                // (Karty kelimesindeki kuralın aynısı, §2.11).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    unit.title,
                    maxLines: 1,
                    style: TextStyle(
                      color: locked ? _C.value : Colors.white,
                      fontSize: 66 * s,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: 14 * s),
                locked
                    ? _LockedHint(
                        scale: s,
                        text: unit.unlockHint ??
                            '${unit.wordCount} kelime seni bekliyor',
                      )
                    : _UnitProgress(
                        unit: unit,
                        scale: s,
                        consolidated: consolidated,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitProgress extends StatelessWidget {
  const _UnitProgress({
    required this.unit,
    required this.scale,
    this.consolidated,
  });

  final KartyUnit unit;
  final double scale;
  final double? consolidated;

  @override
  Widget build(BuildContext context) {
    final barHeight = 20 * scale;
    final count = consolidated ?? unit.consolidatedCount.toDouble();
    final ratio =
        unit.wordCount == 0 ? 0.0 : (count / unit.wordCount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${count.round()}/${unit.wordCount} kelime pekişti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * scale,
            fontWeight: AppTypography.label,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
        SizedBox(height: 12 * scale),
        // Halkadaki ölçünün aynısı: dolgu pekişen kelime, çentik ünite hedefi.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _C.accentDepth,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: math.max(barHeight, width * ratio),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * unit.unlockGoal - 2.5 * scale,
                    top: -5 * scale,
                    bottom: -5 * scale,
                    width: 5 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LockedHint extends StatelessWidget {
  const _LockedHint({required this.scale, required this.text});

  final double scale;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KartyLockMark(size: 30 * scale),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            style: TextStyle(
              color: _C.muted,
              fontSize: 22 * scale,
              fontWeight: AppTypography.label,
              fontFamily: AppTypography.family,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}
