import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';

/// `GET karty/path` yanıtının ekran modeline çevrilmesi: durumlar, Türkçe
/// tarih etiketleri, kilitli ünitenin açılma koşulu, yarının geri sayımı.
void main() {
  final json = <String, dynamic>{
    'units': [
      {
        'sequence': 1,
        'title': 'İlk kelimeler',
        'state': 'current',
        'wordCount': 16,
        'consolidatedCount': 3,
        'unlockGoal': 0.8,
        'emblemUrl': 'https://s3/haus.png',
        'steps': [
          {
            'state': 'done',
            'day': '2026-11-02',
            'newCount': 8,
            'newGoal': 8,
            'reviewCount': 0,
            'dueCount': 2,
            'words': [
              {
                'kartyId': 1,
                'nounText': 'Haus',
                'article': 'das',
                'kartyUrl': 'https://s3/haus.png',
                'box': 3,
                'isDue': false,
              },
            ],
            'upcomingImageUrls': <String>[],
          },
          {
            'state': 'today',
            'day': '2026-11-04',
            'newCount': 3,
            'newGoal': 8,
            'reviewCount': 5,
            'dueCount': 0,
            'words': <dynamic>[],
            'upcomingImageUrls': <String>[],
          },
          {
            'state': 'tomorrow',
            'newCount': 0,
            'newGoal': 5,
            'reviewCount': 2,
            'dueCount': 0,
            'words': <dynamic>[],
            'upcomingImageUrls': ['https://s3/a.png', 'https://s3/b.png'],
          },
        ],
      },
      {
        'sequence': 2,
        'title': 'Yeni kelimeler',
        'state': 'locked',
        'wordCount': 12,
        'consolidatedCount': 0,
        'unlockGoal': 0.8,
        'steps': [
          {
            'state': 'locked',
            'newCount': 0,
            'newGoal': 8,
            'reviewCount': 0,
            'dueCount': 0,
            'words': <dynamic>[],
            'upcomingImageUrls': <String>[],
          },
        ],
      },
    ],
    'dailyNewWordLimit': 8,
    'tomorrowStartsAtUtc': '2026-11-04T21:00:00Z',
  };

  test('yanıt ekran modeline çevrilir', () {
    final requested = <String>[];
    final data = KartyPathData.fromResponse(
      KartyPathResponse.fromJson(json),
      tickets: 12,
      image: (url) {
        requested.add(url);
        return MemoryImage(Uint8List(0));
      },
    );

    expect(data.tickets, 12);
    final first = data.units.first;
    expect(first.state, KartyUnitState.current);
    expect(first.emblem, isNotNull);

    final done = first.steps[0];
    expect(done.state, KartyStepState.done);
    expect(done.label, '2 Kas');
    expect(done.title, '2 Kasım');
    expect(done.dueCount, 2);
    expect(done.words.single.word, 'Haus');

    final today = first.steps[1];
    expect(today.label, 'Bugün');
    expect(today.newCount, 3);
    expect(today.reviewCount, 5);

    final tomorrow = first.steps[2];
    expect(tomorrow.label, 'Yarın');
    expect(tomorrow.upcoming, hasLength(2));
    // Saat dilimi: sunucu UTC gönderir, kalan süre UTC'ye göre hesaplanır.
    expect(
      tomorrow.remainingText(DateTime.utc(2026, 11, 4, 15, 48)),
      '5 sa 12 dk',
    );
    expect(tomorrow.remainingText(DateTime.utc(2026, 11, 4, 20, 30)), '30 dk');
    expect(tomorrow.remainingText(DateTime.utc(2026, 11, 4, 22)), isNull);

    final locked = data.units[1];
    expect(locked.state, KartyUnitState.locked);
    expect(locked.unlockHint, "Ünite 1'in %80'i pekişince açılır");
    expect(requested, contains('https://s3/a.png'));
  });
}
