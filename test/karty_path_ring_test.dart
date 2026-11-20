import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';

/// Pekiştirme halkasının taşları kelime sayısından bağımsız: halka hep
/// yoldaki boyda 16 taş (kullanıcı, 19 Kas 2026: kelime başına taş 24
/// kelimede küçülüp inceliyordu). Yanan taş pekişen kelimenin oranından
/// gelir; çentiğe tam hedefte varılır.
void main() {
  test('çentiğe hedefte varılır, halka hepsi pekişince dolar', () {
    for (final goal in [0.8, 0.75, 0.6]) {
      for (final words in [3, 8, 16, 24, 40]) {
        const stones = 16;
        final needed = kartyRingGoalStones(goal: goal, stones: stones);
        var previous = 0;
        for (var c = 0; c <= words; c++) {
          final ratio = c / words;
          final lit = kartyRingLitStones(
            ratio: ratio,
            goal: goal,
            stones: stones,
          );
          final reason = 'hedef $goal, $c/$words kelime → $lit taş';
          expect(lit >= needed, ratio >= goal, reason: reason);
          expect(lit == 0, c == 0, reason: reason);
          expect(lit == stones, c == words, reason: reason);
          expect(lit, greaterThanOrEqualTo(previous), reason: reason);
          previous = lit;
        }
      }
    }
  });

  test('%80 hedefte çentik 16 taşın 13.sünden sonra', () {
    expect(kartyRingGoalStones(goal: 0.8, stones: 16), 13);
  });
}
