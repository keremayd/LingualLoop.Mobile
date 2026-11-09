import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';

/// `GET karty/path` yanıtının ekran modeline çevrilmesi: deste durumları ve
/// etiketleri, yalnız tekrar adımı, kilitli ünitenin açılma koşulu.
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
            'deck': 1,
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
            'state': 'current',
            'deck': 2,
            'newCount': 3,
            'newGoal': 8,
            'reviewCount': 5,
            'dueCount': 0,
            'words': <dynamic>[],
            'upcomingImageUrls': <String>[],
          },
          {
            'state': 'upcoming',
            'deck': 3,
            'newCount': 0,
            'newGoal': 5,
            'reviewCount': 0,
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
            'deck': 1,
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
    'deckSize': 8,
  };

  test('yanıt ekran modeline çevrilir', () {
    final requested = <String>[];
    final data = KartyPathData.fromResponse(
      KartyPathResponse.fromJson(json),
      image: (url) {
        requested.add(url);
        return MemoryImage(Uint8List(0));
      },
    );

    final first = data.units.first;
    expect(first.state, KartyUnitState.current);
    expect(first.emblem, isNotNull);

    final done = first.steps[0];
    expect(done.state, KartyStepState.done);
    expect(done.deck, 1);
    expect(done.label, 'Deste 1');
    expect(done.title, 'Deste 1');
    expect(done.dueCount, 2);
    expect(done.words.single.word, 'Haus');

    final current = first.steps[1];
    expect(current.state, KartyStepState.current);
    expect(current.label, 'Deste 2');
    expect(current.newCount, 3);
    expect(current.reviewCount, 5);

    final upcoming = first.steps[2];
    expect(upcoming.state, KartyStepState.upcoming);
    expect(upcoming.label, 'Deste 3');
    expect(upcoming.upcoming, hasLength(2));

    final locked = data.units[1];
    expect(locked.state, KartyUnitState.locked);
    expect(locked.unlockHint, "Ünite 1'in %80'i pekişince açılır");
    expect(requested, contains('https://s3/a.png'));
  });

  test('desteler bitince şu anki adım yalnız tekrardır', () {
    final data = KartyPathData.fromResponse(
      KartyPathResponse.fromJson({
        'units': [
          {
            'sequence': 1,
            'title': 'İlk kelimeler',
            'state': 'current',
            'wordCount': 8,
            'consolidatedCount': 3,
            'unlockGoal': 0.8,
            'steps': [
              {
                'state': 'done',
                'deck': 1,
                'newCount': 8,
                'newGoal': 8,
                'reviewCount': 0,
                'dueCount': 0,
              },
              {
                'state': 'current',
                'newCount': 0,
                'newGoal': 0,
                'reviewCount': 4,
                'dueCount': 0,
              },
            ],
          },
        ],
        'deckSize': 8,
      }),
      image: (_) => MemoryImage(Uint8List(0)),
    );

    final review = data.units.single.steps.last;
    expect(review.state, KartyStepState.current);
    expect(review.deck, isNull);
    expect(review.label, 'Tekrar');
    expect(review.newGoal, 0);
    expect(review.reviewCount, 4);
  });
}
