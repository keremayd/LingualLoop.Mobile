import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Seri koruma sayacının ikonu — **buz tutmuş alev**.
///
/// Üst şeritte de profilde de bu kullanılıyor; ikisi de "kaç korumam var"
/// sorusunu cevaplıyor.
///
/// ## Neden bu kadar sade
///
/// Bu ikon uzun süre 3B kristal olarak denendi (hem painter hem üretilmiş
/// PNG) ve hepsi 40 pikselde çöktü. Duolingo'nun kendi seri koruma ikonu
/// ölçülünce sebep anlaşıldı — onlar **çıkarma** yapmış:
///
/// | | Duolingo | Bizim denemelerimiz |
/// |---|---|---|
/// | Nesne | **1** siluet | 2 (kap + içindeki) |
/// | İç şekil | 3 düz alan + 2 parıltı | 7 faset + doku + hâle |
/// | Gradyan/doku | yok | var |
/// | Buz işareti | alttaki **damlalar** | fasetler, sarkıtlar, kırağı |
///
/// Kural: 40 pikselde bir kutuya **iki nesne sığmaz**. Yanındaki bilet,
/// seviye ve lig ikonlarının hepsi tek nesne; okunmalarının sebebi bu. Bu
/// yüzden buz ile alev iki ayrı cisim değil **tek siluet**: alevin kendisi,
/// alt kenarından buz damlıyor.
///
/// Duolingo'nun kalın beyaz konturu **alınmadı** — uygulamamızda kontur yok,
/// derinliği kalınlık bandı veriyor (§2.5/2).
///
/// Siluet uydurma değil: uygulamanın kendi alev yolu (`streakFlameBody`),
/// yani kullanıcının profilde ve görevlerde gördüğü şeklin aynısı. Değişen
/// tek şey malzemesi.
class StreakFreezeFlake extends StatelessWidget {
  const StreakFreezeFlake({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FrozenFlamePainter(),
    );
  }
}

class _FrozenFlamePainter extends CustomPainter {
  // §2.6'daki `kuyruklu` buz üçlüsü; bant ondan türetildi.
  static const _light = Color(0xFFE4F8FF);
  static const _face = Color(0xFF9BDCF4);
  static const _deep = Color(0xFF4E9CC4);
  static const _band = Color(0xFF2A6E96);

  /// Alev, damlalara yer açmak için hafif küçültülüp yukarı alınıyor.
  Matrix4 _flameMatrix(double u) => Matrix4.identity()
    ..translate(50 * u, 46 * u)
    ..scale(0.84)
    ..translate(-50 * u, -50 * u);

  /// Alt kenardan sarkan buz damlaları — buzu anlatan **tek** işaret.
  /// Boyları ve konumları bilerek eşit değil; eşit olsalar taraklaşıp
  /// manüfaktür bir cisme dönerlerdi.
  /// (x, üst, yarı genişlik, uzunluk)
  ///
  /// Genişlikler **kalınlık bandı payı düşülerek** seçildi: gövde 6–8 birimlik
  /// yuvarlak konturla çevriliyor ve bu her damlaya iki yandan ~3 birim
  /// ekliyor. İlk denemede yarı genişlikler 6–8'di ve kontur eklenince damla
  /// 18–22 birime çıkıyordu; su o kalınlıkta damlamaz, sarkıt gibi duruyordu.
  static const _drips = <List<double>>[
    [34, 70, 3, 18],
    [50, 74, 3.5, 25],
    [66, 68, 2.5, 14],
  ];

  Path _drip(double u, List<double> d, double dy) {
    final x = d[0] * u;
    final top = (d[1] + dy) * u;
    final w = d[2] * u;
    final bottom = (d[1] + d[3] + dy) * u;
    return Path()
      ..moveTo(x - w, top)
      ..quadraticBezierTo(x - w, bottom, x, bottom)
      ..quadraticBezierTo(x + w, bottom, x + w, top)
      ..close();
  }

  /// Alev + damlalar **tek** siluet olarak.
  ///
  /// `addPath` ile eklemek yetmiyor: bileşik bir yol konturlandığında her alt
  /// yol ayrı ayrı çevriliyor ve damlaların alevin **içinde kalan** kenarları
  /// çizgi olarak görünüyor — nesne tek gövde değil, dişler gibi okunuyordu.
  /// `Path.combine(union)` gerçek birleşim üretiyor, kontur da dış hattı
  /// dolaşıyor.
  Path _silhouette(double u, double dy) {
    var path = streakFlameBody(u)
        .transform(_flameMatrix(u).storage)
        .shift(Offset(0, dy * u));
    for (final drip in _drips) {
      path = Path.combine(PathOperation.union, path, _drip(u, drip, dy));
    }
    return path;
  }

  void _fillChunky(Canvas canvas, Path path, Color color, double u,
      {double stroke = 6}) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final isCompact = size.width < 46;
    final stroke = isCompact ? 8.0 : 6.0;

    // 1 — Kalınlık bandı.
    _fillChunky(canvas, _silhouette(u, isCompact ? 8 : 5), _band, u,
        stroke: stroke);

    // 2 — Gövde.
    _fillChunky(canvas, _silhouette(u, 0), _face, u, stroke: stroke);

    canvas.save();
    canvas.clipPath(_silhouette(u, 0));

    // 3 — Tek koyu bant: sağ-alt yarı gölgede. Duolingo'daki çapraz ayrımın
    //     karşılığı; hacmi tek kenarla veriyor, faset gerekmiyor.
    canvas.drawPath(
      Path()
        ..moveTo(26 * u, 108 * u)
        ..lineTo(74 * u, 14 * u)
        ..lineTo(108 * u, 14 * u)
        ..lineTo(108 * u, 108 * u)
        ..close(),
      Paint()..color = _deep.withValues(alpha: 0.9),
    );

    // 4 — Tek açık alan: sol üst, ışığa dönük yüz.
    canvas.drawPath(
      Path()
        ..moveTo(-8 * u, -8 * u)
        ..lineTo(44 * u, -8 * u)
        ..lineTo(16 * u, 62 * u)
        ..lineTo(-8 * u, 62 * u)
        ..close(),
      Paint()..color = _light,
    );

    // 5 — Buzun içinde donmuş alevin izi.
    //
    //     Siluet zaten alev biçiminde ama tek renkli olduğu için "bu ne"
    //     sorusu 40 pikselde havada kalıyordu. Alevin **iç dili**
    //     (`streakFlameInner`, uygulamanın kendi yolu) buzun altından
    //     hafifçe görünüyor: sıcak ton, düşük opaklık. Şeffaflık yine
    //     bulanıklıkla değil **örtüşmeyle** anlatılıyor (§2.2).
    //
    //     Ton **krem** (`FFF1DC`), doymuş altın değil. İlk denemede
    //     `FFC24D` %16–42 opaklıkla konuldu ve mavinin üstünde **zeytin**
    //     rengine döndü — CLAUDE.md'de kayıtlı tuzak: doymuş sıcak ton yarı
    //     saydam kullanılamaz. Krem beyaza yeterince yakın olduğu için
    //     kirletmiyor ama sıcaklığı taşıyor.
    canvas.save();
    canvas.transform(_flameMatrix(u).storage);
    canvas.drawPath(
      streakFlameInner(u),
      Paint()..color = const Color(0xFFFFF1DC).withValues(alpha: 0.62),
    );
    canvas.restore();

    // 6 — Parıltılar: dört köşeli küçük elmaslar. Buzun kristal olduğunu
    //     söyleyen tek doku; Duolingo'da da yalnız iki tane var.
    void spark(double x, double y, double r) {
      canvas.drawPath(
        Path()
          ..moveTo(x * u, (y - r) * u)
          ..quadraticBezierTo(x * u, y * u, (x + r) * u, y * u)
          ..quadraticBezierTo(x * u, y * u, x * u, (y + r) * u)
          ..quadraticBezierTo(x * u, y * u, (x - r) * u, y * u)
          ..quadraticBezierTo(x * u, y * u, x * u, (y - r) * u)
          ..close(),
        Paint()..color = Colors.white,
      );
    }

    spark(37, 36, isCompact ? 6 : 5);
    if (!isCompact) spark(62, 58, 3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
