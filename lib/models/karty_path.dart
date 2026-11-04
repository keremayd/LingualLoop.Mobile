import 'package:flutter/widgets.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';

/// Karty Yolu'nun ekran modeli: ünite → adım (8 yeni kelimelik deste) →
/// kelime. Sunucudaki karşılığı `GET karty/path/{userId}`
/// ([KartyPathResponse]); ekran yalnız bu modeli tanır.
class KartyPathData {
  const KartyPathData({required this.tickets, required this.units});

  final int tickets;
  final List<KartyUnit> units;

  /// Sunucu yanıtını ekran modeline çevirir. [image] testte yerel görsel
  /// vermek için; uygulamada imzalı adresten [NetworkImage].
  factory KartyPathData.fromResponse(
    KartyPathResponse response, {
    required int tickets,
    ImageProvider Function(String url) image = _network,
  }) {
    KartyStepState stepState(String state) => switch (state) {
          'done' => KartyStepState.done,
          'today' => KartyStepState.today,
          'tomorrow' => KartyStepState.tomorrow,
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
            : 'Ünite ${previous.number}${_genitive(previous.number)} '
                '%${(unit.unlockGoal * 100).round()}\'i pekişince açılır',
        steps: [
          for (final step in unit.steps)
            KartyStep(
              state: stepState(step.state),
              label: _label(stepState(step.state), step.day, short: true),
              title: _label(stepState(step.state), step.day, short: false),
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
              opensAt: stepState(step.state) == KartyStepState.tomorrow
                  ? response.tomorrowStartsAtUtc
                  : null,
            ),
        ],
      ));
    }
    return KartyPathData(tickets: tickets, units: units);
  }

  static ImageProvider _network(String url) => NetworkImage(url);

  static const _monthsShort = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', //
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  /// Yol üstü etiketi ("2 Kas") ya da pencere başlığı ("2 Kasım").
  static String _label(KartyStepState state, String? day,
      {required bool short}) {
    switch (state) {
      case KartyStepState.today:
        return 'Bugün';
      case KartyStepState.tomorrow:
        return 'Yarın';
      case KartyStepState.done:
        final date = day == null ? null : DateTime.tryParse(day);
        if (date == null) return '';
        final months = short ? _monthsShort : _months;
        return '${date.day} ${months[date.month - 1]}';
      case KartyStepState.upcoming:
      case KartyStepState.locked:
        return '';
    }
  }

  /// Sayının ilgi hâli eki: 1'in, 2'nin, 3'ün, 6'nın, 10'un.
  static String _genitive(int n) {
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

enum KartyStepState { done, today, tomorrow, upcoming, locked }

/// Patikadaki bir düğüm: 8 yeni kelimelik deste. Günlük yeni kelime tavanı 8
/// olduğu için her gün oynayan kullanıcıda bir adım bir güne denk gelir.
class KartyStep {
  const KartyStep({
    required this.state,
    this.label = '',
    this.title = '',
    this.newCount = 0,
    this.newGoal = 8,
    this.reviewCount = 0,
    this.dueCount = 0,
    this.words = const [],
    this.upcoming = const [],
    this.opensAt,
    this.opensIn,
  });

  final KartyStepState state;

  /// Yol üstündeki kısa etiket: "1 Kas", "Bugün", "Yarın".
  final String label;

  /// Adım penceresinin başlığı: "2 Kasım".
  final String title;

  /// Bu destede tanışılan yeni kelime / hedef (bugün için 3/8).
  final int newCount;
  final int newGoal;

  /// O gün yapılacak tekrar sayısı (bugün ve yarın için).
  final int reviewCount;

  /// Bu destede vadesi gelmiş kelime sayısı — geçmiş düğümün rozeti.
  final int dueCount;

  final List<KartyWord> words;

  /// Henüz açılmamış kelimelerin görselleri; pencerede siluet olarak durur.
  final List<ImageProvider> upcoming;

  /// Yarının açıldığı an (UTC). Kalan süre pencere açılınca hesaplanır.
  final DateTime? opensAt;

  /// Hazır kalan süre metni ("5 sa 12 dk"); önizlemede sabit süre için.
  final String? opensIn;

  /// Pencerede gösterilecek kalan süre: [opensIn] ya da [opensAt]'ten.
  String? remainingText(DateTime now) {
    if (opensIn != null) return opensIn;
    final opensAt = this.opensAt;
    if (opensAt == null) return null;
    final left = opensAt.difference(now.toUtc());
    if (left.isNegative) return null;
    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    return hours > 0 ? '$hours sa $minutes dk' : '${left.inMinutes} dk';
  }
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
