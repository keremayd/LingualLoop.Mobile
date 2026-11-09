import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// "Buraya dokun" hareketi: Görevler'de alınabilir ödül, patikada şu anki
/// düğüm. İkisi aynı eğriyi paylaşır, uygulamada tek bir zıplama var.
///
/// Döngünün ilk %30'unda sıçrar, kalanında durur: aralıksız zıplayan öğe
/// birkaç saniyede gürültüye dönüşür. Dinlenmede yükseklik ve eziliş tam
/// sıfır olduğu için `repeat()` döngüsü atlamadan kapanır.
abstract final class HopMotion {
  static const duration = Duration(milliseconds: 1900);

  /// Sıçrama yüksekliği (tasarım birimi).
  static const height = 12.0;

  /// Döngünün zıplamaya ayrılan kısmı ve iniş sonrası eziliş penceresi.
  static const _hopSpan = 0.30;
  static const _squashSpan = 0.09;

  /// Döngünün [v] anındaki yükseklik (0–1) ve iniş ezilişi (0–1).
  static ({double lift, double squash}) at(double v) {
    if (v < _hopSpan) {
      final p = v / _hopSpan;
      if (p < 0.42) {
        // Çıkış: hızlı başlar, zirveye yavaşlayarak varır.
        return (lift: Curves.easeOut.transform(p / 0.42), squash: 0);
      }
      // İniş: zirvede yavaş, yere doğru hızlanır.
      final f = (p - 0.42) / 0.58;
      return (lift: 1 - Curves.easeIn.transform(f), squash: 0);
    }
    if (v < _hopSpan + _squashSpan) {
      // Yere değdikten hemen sonra kısa bir eziliş: sıçramaya ağırlık verir.
      return (
        lift: 0,
        squash: math.sin(math.pi * (v - _hopSpan) / _squashSpan),
      );
    }
    return (lift: 0, squash: 0);
  }

  /// İniş ezilişi: hacim korunsun diye yatayda genişleyip dikeyde kısalır.
  /// `Alignment.bottomCenter` ile uygulanır, alttan basılmış gibi yayılsın.
  static Matrix4 squash(double amount) => Matrix4.diagonal3Values(
        1 + 0.09 * amount,
        1 - 0.11 * amount,
        1,
      );
}
