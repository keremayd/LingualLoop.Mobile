import 'package:lingualloop/models/karty_path.dart';

/// Oyunun Karty Yolu'nda hangi adımdan açıldığı (`/kartyquiz` rota
/// argümanı). Yoksa oyun eski sonsuz akışta açılır (ör. Artikel'in kilitli
/// ekranından) ve özet gösterilmez.
class KartySessionArgs {
  const KartySessionArgs({
    required this.unit,
    this.deck,
    this.reviewCount = 0,
  });

  /// Adımın ünitesi, oyun başındaki hâliyle: özetteki ünite çubuğu buradan
  /// başlar.
  final KartyUnit unit;

  /// Oynanacak deste; yalnız tekrar adımında null.
  final int? deck;

  /// Oyun başında vadesi gelmiş tekrar. Deste yokken bu da sıfırsa oyun
  /// baştan pratiktir: bitişi sunucu değil tur uzunluğu belirler.
  final int reviewCount;

  /// Bitişi sorulacak bir işi var mı.
  bool get hasWork => deck != null || reviewCount > 0;
}
