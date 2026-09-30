import 'package:lingualloop/ui/app_typography.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Son yedi günün seri şeridi: hangi gün girildi, hangi gün korumayla
/// kurtarıldı, hangi gün boş geçti.
///
/// Üç durum ayrı ayrı okunur — "girilmedi" ile "korundu" aynı şey değildir.
/// İkisi aynı gösterilseydi kullanıcı şeritte boş bir gün görüp "ama serim
/// neden devam ediyor?" diye şaşırırdı.
///
/// | Durum | Gösterim |
/// |---|---|
/// | Girildi | Alev rengi tombul disk, içinde onay |
/// | Korundu | Buz mavisi tombul disk, içinde **buz tutmuş onay** |
/// | Boş | İçi boş, kesikli konturlu halka |
///
/// İşaretler §2.5 reçetesiyle çizilir (kalınlık bandı + net alan ayrımı);
/// Material'ın hazır ikonları bilinçli olarak kullanılmaz.
class StreakWeekStrip extends StatelessWidget {
  const StreakWeekStrip({
    super.key,
    required this.days,
    required this.scale,
    this.markerKeys,
  });

  final List<StreakDay> days;
  final double scale;

  /// Gün kutularına takılacak anahtarlar (gün sayısıyla aynı uzunlukta).
  ///
  /// Koruma animasyonu kalkanı **hangi güne** saplayacağını bilmek zorunda;
  /// hedefin ekrandaki yeri ancak yerleşimden sonra bilinebiliyor, bu yüzden
  /// dışarıdan anahtar verilebiliyor.
  final List<GlobalKey>? markerKeys;

  static const _muted = Color(0xFF8FA0B5);

  /// Pazartesi'den Pazar'a Türkçe gün kısaltmaları.
  ///
  /// **Tek harf kullanılamaz:** Türkçede Pazartesi, Perşembe ve Pazar aynı
  /// harfle başlıyor — şerit `P S Ç P C C P` olarak okunuyor ve hangi P'nin
  /// hangi gün olduğu ayırt edilemiyordu. Kullanıcı pazartesideki tiki pazar
  /// sanıp "seri 0 ama bugün tikli" diye hata bildirdi; veri doğruydu,
  /// **etiket yanlıştı.**
  ///
  /// İki harf hem ayırt edici hem dar şeride sığıyor (üç harfli `Pzt/Per/Paz`
  /// ana ekrandaki 33 birimlik sütuna sığmıyor).
  static const _initials = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < days.length; index++)
          _dayColumn(days[index], markerKeys?[index]),
      ],
    );
  }

  Widget _dayColumn(StreakDay day, GlobalKey? markerKey) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _initials[day.date.weekday - 1],
          style: TextStyle(
            color: day.isToday ? Colors.white : _muted,
            fontSize: 22 * scale,
            fontWeight:
                day.isToday ? AppTypography.label : AppTypography.caption,
            fontFamily: AppTypography.family,
          ),
        ),
        SizedBox(height: 9 * scale),
        StreakDayMark(
          key: markerKey,
          size: 54 * scale,
          active: day.active,
          frozen: day.frozen,
        ),
      ],
    );
  }
}

/// Seri takvimindeki tek gün işareti.
///
/// [frozen] her zaman [active]'den önceliklidir. Böylece servis iki bayrağı
/// birlikte döndürse bile korumayla tamamlanan gün normal oynanmış gibi
/// görünmez.
class StreakDayMark extends StatelessWidget {
  const StreakDayMark({
    super.key,
    required this.size,
    required this.active,
    required this.frozen,
  });

  final double size;
  final bool active;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DayMarkPainter(
        active: active && !frozen,
        frozen: frozen,
        scale: size / 54,
      ),
    );
  }
}

/// Şeritteki tek gün.
class StreakDay {
  const StreakDay({
    required this.date,
    required this.active,
    required this.frozen,
    required this.isToday,
  });

  final DateTime date;
  final bool active;
  final bool frozen;
  final bool isToday;
}

class _DayMarkPainter extends CustomPainter {
  const _DayMarkPainter({
    required this.active,
    required this.frozen,
    required this.scale,
  });

  final bool active;
  final bool frozen;
  final double scale;

  static const _flameFace = Color(0xFFFF6536);
  static const _flameDepth = Color(0xFF9A1414);
  static const _iceFace = Color(0xFF1CB1F5);
  static const _iceDepth = Color(0xFF0E6A98);
  static const _emptyRing = Color(0xFF163258);
  static const _mark = Color(0xFFFFFFFF);

  static const _dashCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    if (!active && !frozen) {
      _paintEmptyRing(canvas, size);
      return;
    }

    _paintDisc(
      canvas,
      u,
      face: active ? _flameFace : _iceFace,
      depth: active ? _flameDepth : _iceDepth,
    );

    if (active) {
      _paintCheck(canvas, u);
    } else {
      _paintFrozenCheck(canvas, u);
    }
  }

  /// §2.5/2: gövdenin kopyası aşağı kaydırılıp koyu tonda çizilir.
  void _paintDisc(
    Canvas canvas,
    double u, {
    required Color face,
    required Color depth,
  }) {
    final disc = Path()
      ..addOval(
          Rect.fromCircle(center: Offset(50 * u, 47 * u), radius: 44 * u));

    canvas.drawPath(disc.shift(Offset(0, 6 * u)), Paint()..color = depth);
    canvas.drawPath(disc, Paint()..color = face);
  }

  /// `_QuestCheckPainter` ile aynı onay geometrisi: küçük boyutta bulanmasın
  /// diye gölgesiz ve kalın.
  void _paintCheck(Canvas canvas, double u) {
    final check = Path()
      ..moveTo(28 * u, 48 * u)
      ..lineTo(43 * u, 63 * u)
      ..lineTo(73 * u, 31 * u);

    canvas.drawPath(
      check,
      Paint()
        ..color = _mark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Buz tutmuş onay işareti.
  ///
  /// Korunan gün, girilen günle **aynı onay işaretini** taşır: o gün seride
  /// sayılıyor. Farkı nasıl sayıldığı — kazanılarak değil korunarak. Bunu buz
  /// kaplaması anlatıyor. Kar tanesi denendi ve geri alındı: güzel bir simge
  /// ama "gün" ile ilgisi yok, şeritte yabancı duruyordu.
  ///
  /// Buz keskin kenarlı fasetlerle çizilir, bulanık gradyanla değil (§2.2
  /// gradyan bulanıklığını yasaklıyor); kristal zaten keskin bir şeydir.
  void _paintFrozenCheck(Canvas canvas, double u) {
    final center = Offset(50 * u, 47 * u);
    final radius = 44 * u;

    // Önce onay: buzun altında kalacak.
    _paintCheck(canvas, u);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Kenardan içeri doğru uzayan kırağı dişleri — donma dıştan içe ilerler.
    _paintFrostTeeth(canvas, center, radius);

    // İki buz faseti: biri geniş ve parlak, diğeri dar. Tek faset düz bir
    // filtre gibi okunuyor; ikisi kırılma hissi veriyor.
    canvas.drawPath(
      Path()
        ..moveTo(-4 * u, 36 * u)
        ..lineTo(44 * u, 2 * u)
        ..lineTo(70 * u, 26 * u)
        ..lineTo(22 * u, 60 * u)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.drawPath(
      Path()
        ..moveTo(62 * u, 100 * u)
        ..lineTo(104 * u, 58 * u)
        ..lineTo(104 * u, 88 * u)
        ..lineTo(82 * u, 104 * u)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );

    // Kenarda buz kabuğu. Fasetler ve dişler gerçek boyutta (≈29pt) neredeyse
    // görünmüyor; disk sadece "mavi tik" gibi okunuyordu. Kabuk her boyutta
    // duruyor ve "kaplanmış" bilgisini tek başına taşıyor.
    canvas.drawCircle(
      center,
      radius - 3 * u,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * u,
    );

    // Fasetin üst kenarında ince parlama: ışığın buz yüzeyinde kırıldığı yer.
    canvas.drawLine(
      Offset(-4 * u, 36 * u),
      Offset(44 * u, 2 * u),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * u,
    );

    canvas.restore();
  }

  /// Diskin kenarından merkeze doğru uzanan kırağı dişleri.
  ///
  /// Açı, uzunluk ve genişlik üçü birden düzensiz. Yalnızca uzunluğu
  /// değiştirmek yetmiyordu: eşit aralık ve eşit genişlik dişli çark gibi
  /// okunuyordu. Kırağı düzensiz büyür.
  void _paintFrostTeeth(Canvas canvas, Offset center, double radius) {
    // (açı derece, uzunluk oranı, yarım genişlik radyan)
    const teeth = <List<double>>[
      [-108, 0.46, 0.30],
      [-52, 0.24, 0.18],
      [-6, 0.38, 0.26],
      [44, 0.20, 0.15],
      [92, 0.42, 0.32],
      [148, 0.28, 0.20],
      [206, 0.44, 0.24],
    ];
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.44);

    Offset onRim(double angle) =>
        center + Offset(math.cos(angle), math.sin(angle)) * radius;

    for (final tooth in teeth) {
      final angle = tooth[0] * math.pi / 180;
      final tip = center +
          Offset(math.cos(angle), math.sin(angle)) * radius * (1 - tooth[1]);

      canvas.drawPath(
        Path()
          ..moveTo(onRim(angle - tooth[2]).dx, onRim(angle - tooth[2]).dy)
          ..lineTo(onRim(angle + tooth[2]).dx, onRim(angle + tooth[2]).dy)
          ..lineTo(tip.dx, tip.dy)
          ..close(),
        paint,
      );
    }
  }

  /// Boş gün: dolu bir daire "bir şey oldu" der. Girilmemiş gün, olmamış bir
  /// şeydir — içi boş ve kesikli kontur onu söyler.
  void _paintEmptyRing(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2 * scale;
    final paint = Paint()
      ..color = _emptyRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;

    const sweep = math.pi * 2 / _dashCount;
    for (var index = 0; index < _dashCount; index++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        index * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayMarkPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.frozen != frozen ||
        oldDelegate.scale != scale;
  }
}

/// Buz bloğu bir güne çakıldığı anda o kutudan çıkan don dalgası.
///
/// Halka + kıymıklar; bulanık gradyan ya da parlama kullanılmıyor (§2.2 neon
/// ve gradyan bulanıklığını yasaklıyor). Kıymıklar bloğun kırağı
/// parıltılarıyla aynı dört uçlu biçim — patlama yabancı bir dil konuşmasın.
class StreakFrostBurst extends StatelessWidget {
  const StreakFrostBurst({
    super.key,
    required this.size,
    required this.progress,
  });

  final double size;

  /// 0 → 1. Çarpma anında 0'dan başlar.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _FrostBurstPainter(progress: progress),
      ),
    );
  }
}

class _FrostBurstPainter extends CustomPainter {
  const _FrostBurstPainter({required this.progress});

  final double progress;

  static const _ice = Color(0xFF1CB1F5);
  static const _shardCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    // Genişleyen halka: hızlı açılır, açılırken incelir ve söner.
    final ringProgress = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      maxRadius * (0.22 + ringProgress * 0.74),
      Paint()
        ..color = _ice.withValues(alpha: 0.9 * fade * fade * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxRadius * 0.10 * fade,
    );

    // Kıymıklar kutunun kenarından dışa savrulur. Merkeze kümelendiklerinde
    // patlama değil rozet gibi okunuyorlardı.
    final shardProgress = Curves.easeOutCubic.transform(progress);
    for (var index = 0; index < _shardCount; index++) {
      final angle = index * math.pi * 2 / _shardCount + 0.2;
      final distance = maxRadius * (0.34 + shardProgress * 0.60);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final shardSize = maxRadius * 0.13 * fade;
      if (shardSize <= 0.2) continue;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + progress * 1.4);
      canvas.drawPath(
        _shard(shardSize),
        Paint()..color = Colors.white.withValues(alpha: 0.95 * fade),
      );
      canvas.restore();
    }
  }

  /// Bloğun parıltısıyla aynı dört uçlu biçim.
  Path _shard(double radius) {
    final waist = radius * 0.18;
    return Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(waist, -waist, radius, 0)
      ..quadraticBezierTo(waist, waist, 0, radius)
      ..quadraticBezierTo(-waist, waist, -radius, 0)
      ..quadraticBezierTo(-waist, -waist, 0, -radius)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _FrostBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
