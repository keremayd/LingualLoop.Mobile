import 'package:flutter/widgets.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';

/// Karty Yolu'nun ekran modeli: ünite → deste (8 kelime) → kelime. Sunucudaki karşılığı `GET karty/path/{userId}`
/// ([KartyPathResponse]); ekran yalnız bu modeli tanır.
class KartyPathData {
  const KartyPathData({
    required this.units,
    this.pendingUnlock,
  });

  final List<KartyUnit> units;

  /// Açılıp kutlaması henüz gösterilmemiş ünite; yoksa null.
  final KartyUnitUnlock? pendingUnlock;

  /// [number] sıralı ünitenin açılışı: ünite ve kilidini açan önceki ünite.
  /// İlk ünite hep açık olduğu için onun açılışı yok.
  KartyUnitUnlock? unlockFor(int number) {
    final index = units.indexWhere((unit) => unit.number == number);
    if (index <= 0) return null;
    return KartyUnitUnlock(unlocked: units[index], completed: units[index - 1]);
  }

  /// Sunucu yanıtını ekran modeline çevirir. [image] testte yerel görsel
  /// vermek için; uygulamada imzalı adresten [NetworkImage].
  factory KartyPathData.fromResponse(
    KartyPathResponse response, {
    ImageProvider Function(String url) image = _network,
  }) {
    KartyStepState stepState(String state) => switch (state) {
          'done' => KartyStepState.done,
          'current' => KartyStepState.current,
          'upcoming' => KartyStepState.upcoming,
          _ => KartyStepState.locked,
        };

    final units = <KartyUnit>[];
    for (final unit in response.units) {
      final previous = units.isEmpty ? null : units.last;
      units.add(KartyUnit(
        number: unit.sequence,
        title: unit.title,
        state: switch (unit.state) {
          'done' => KartyUnitState.done,
          'current' => KartyUnitState.current,
          'open' => KartyUnitState.open,
          _ => KartyUnitState.locked,
        },
        wordCount: unit.wordCount,
        consolidatedCount: unit.consolidatedCount,
        unlockGoal: unit.unlockGoal,
        emblem: unit.emblemUrl == null ? null : image(unit.emblemUrl!),
        unlockHint: previous == null
            ? null
            : 'Ünite ${previous.number}${genitive(previous.number)} '
                '%${(unit.unlockGoal * 100).round()}\'i pekişince açılır',
        steps: [
          for (final step in unit.steps)
            KartyStep(
              state: stepState(step.state),
              deck: step.deck,
              label: step.deck == null ? 'Tekrar' : 'Deste ${step.deck}',
              title: step.deck == null ? 'Tekrar' : 'Deste ${step.deck}',
              newCount: step.newCount,
              newGoal: step.newGoal,
              reviewCount: step.reviewCount,
              dueCount: step.dueCount,
              words: [
                for (final word in step.words)
                  KartyWord(
                    word: word.nounText,
                    article: word.article,
                    image: image(word.kartyUrl),
                    box: word.box,
                    due: word.isDue,
                  ),
              ],
              upcoming: [for (final url in step.upcomingImageUrls) image(url)],
            ),
        ],
      ));
    }
    final data = KartyPathData(units: units);
    final pending = response.pendingUnlockSequence;
    return pending == null
        ? data
        : KartyPathData(
            units: units,
            pendingUnlock: data.unlockFor(pending),
          );
  }

  static ImageProvider _network(String url) => NetworkImage(url);

  /// Sayının ilgi hâli eki: 1'in, 2'nin, 3'ün, 6'nın, 10'un.
  static String genitive(int n) {
    const byLastDigit = [
      '',
      "'in",
      "'nin",
      "'ün",
      "'ün",
      "'in",
      "'nın",
      "'nin",
      "'in",
      "'un"
    ];
    const byTens = [
      '',
      "'un",
      "'nin",
      "'un",
      "'ın",
      "'nin",
      "'ın",
      "'in",
      "'in",
      "'ın"
    ];
    if (n % 10 != 0) return byLastDigit[n % 10];
    if (n % 100 != 0) return byTens[(n ~/ 10) % 10];
    return "'ün";
  }
}

enum KartyUnitState { done, current, open, locked }

/// Açılan ünite ve kilidini açan önceki ünite.
class KartyUnitUnlock {
  const KartyUnitUnlock({required this.unlocked, required this.completed});

  final KartyUnit unlocked;
  final KartyUnit completed;

  /// Kapının kuralı, patikadaki kilit cümlesiyle ("Ünite 1'in %80'i
  /// pekişince açılır") aynı dilde.
  String get reason =>
      'Ünite ${completed.number}${KartyPathData.genitive(completed.number)} '
      '%${(completed.unlockGoal * 100).round()}\'ini pekiştirdin.';
}

class KartyUnit {
  const KartyUnit({
    required this.number,
    required this.title,
    required this.state,
    required this.wordCount,
    this.consolidatedCount = 0,
    this.unlockGoal = 0.8,
    this.emblem,
    this.steps = const [],
    this.unlockHint,
  });

  final int number;
  final String title;
  final KartyUnitState state;
  final int wordCount;

  /// `box ≥ 2` olan kelime sayısı. Ünite sonundaki pekiştirme halkası bunu
  /// gösterir; `unlockGoal` oranına ulaşınca sıradaki ünite açılır.
  final int consolidatedCount;
  final double unlockGoal;

  /// Başlıktaki 3B nesne — ünitenin simgesi.
  final ImageProvider? emblem;

  final List<KartyStep> steps;

  /// Kilitli ünitenin açılma koşulu ("Evde'nin %80'i pekişince").
  final String? unlockHint;

  double get consolidatedRatio =>
      wordCount == 0 ? 0 : (consolidatedCount / wordCount).clamp(0.0, 1.0);
}

enum KartyStepState { done, current, upcoming, locked }

/// Patikadaki bir düğüm: ünitenin 8 kelimelik bir destesi. Bir oyun bir
/// destedir; deste bitince sıradaki açılır (bkz. `KartyDeckRules`).
/// Açık bütün desteler bittiyse şu anki adım yalnız tekrardır ([deck] null).
class KartyStep {
  const KartyStep({
    required this.state,
    this.deck,
    this.label = '',
    this.title = '',
    this.newCount = 0,
    this.newGoal = 8,
    this.reviewCount = 0,
    this.dueCount = 0,
    this.words = const [],
    this.upcoming = const [],
  });

  final KartyStepState state;

  /// Ünite içindeki deste numarası; yalnız tekrar adımında null.
  final int? deck;

  /// Yol üstündeki kısa etiket ve pencere başlığı: "Deste 2", "Tekrar".
  final String label;
  final String title;

  /// Bu destede tanışılan kelime / destenin büyüklüğü (3/8).
  final int newCount;
  final int newGoal;

  /// Şu anki adımda: oyunun önce soracağı, vadesi gelmiş tekrar sayısı.
  final int reviewCount;

  /// Bu destede vadesi gelmiş kelime sayısı — bitmiş düğümün rozeti.
  final int dueCount;

  final List<KartyWord> words;

  /// Destenin henüz tanışılmamış kelimelerinin görselleri; pencerede
  /// silüet olarak durur.
  final List<ImageProvider> upcoming;
}

class KartyWord {
  const KartyWord({
    required this.word,
    required this.article,
    required this.image,
    required this.box,
    this.due = false,
  });

  final String word;
  final String article;
  final ImageProvider image;

  /// Leitner kutusu (0–5).
  final int box;
  final bool due;

  bool get consolidated => box >= 2;
}
