import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/word_collection_response.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/word_collection_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';
import 'package:lingualloop/ui/widgets/speaker_mark.dart';
import 'package:provider/provider.dart';

class _UserService extends Fake implements UserService {
  final calls = <String>[];
  bool fail = false;

  @override
  Future<ApiResponse<WordCollectionResponse>> wordCollection({
    String category = 'all',
    int page = 1,
  }) async {
    calls.add('$category:$page');
    if (fail) throw StateError('Bağlantı hatası');
    const word = WordCollectionItem(
      kartyId: 1,
      nounText: 'Koffer',
      article: 'der',
      kartyUrl: '',
      audioUrl: 'test-audio',
      isNew: false,
      isDue: true,
      needsArticlePractice: false,
    );
    return ApiResponse(
        data: WordCollectionResponse(
      totalCount: 1,
      newCount: 0,
      dueCount: 1,
      articleCount: 1,
      filteredCount: category == 'new' ? 0 : 1,
      page: page,
      hasMore: false,
      items: category == 'new' ? const [] : const [word],
    ));
  }
}

class _PronunciationService extends Fake implements PronunciationService {
  @override
  final ValueNotifier<bool> isMuted = ValueNotifier(false);
  @override
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  @override
  Future<void> get ready async {}

  final _playbacks = <Completer<void>>[];

  @override
  Future<void> play(String? url) async {
    final playback = Completer<void>();
    _playbacks.add(playback);
    final index = _playbacks.length - 1;
    isSpeaking.value = true;
    await playback.future;
    if (index == _playbacks.length - 1) isSpeaking.value = false;
  }

  void finish([int? index]) {
    if (_playbacks.isEmpty) return;
    final playback = _playbacks[index ?? _playbacks.length - 1];
    if (!playback.isCompleted) playback.complete();
  }

  @override
  Future<void> stop() async {
    for (final playback in _playbacks) {
      if (!playback.isCompleted) playback.complete();
    }
    isSpeaking.value = false;
  }

  @override
  Future<void> setMuted(bool muted) async {
    isMuted.value = muted;
    if (muted) await stop();
  }
}

void main() {
  testWidgets('Gerçek filtre sonucu ve boş durum gösterilir', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _UserService();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<UserService>.value(value: service),
        Provider<PronunciationService>.value(value: _PronunciationService()),
      ],
      child: const MaterialApp(home: WordCollectionScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 kelimeyle tanıştın'), findsOneWidget);
    expect(find.text('Koffer'), findsOneWidget);
    final newFilter = find.ancestor(
        of: find.text('Yeni'), matching: find.byType(DepthPressableButton));
    expect(newFilter, findsOneWidget);
    final press = await tester.startGesture(tester.getCenter(newFilter));
    await tester.pump(const Duration(milliseconds: 90));
    final filterFace = find.descendant(
        of: newFilter, matching: find.byType(AnimatedPositioned));
    expect(tester.widget<AnimatedPositioned>(filterFace).top, greaterThan(0));
    await press.cancel();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artikel'));
    await tester.pumpAndSettle();
    expect(find.text('Artikel çalış'), findsOneWidget);

    await tester.tap(find.text('Yeni'));
    await tester.pumpAndSettle();
    expect(service.calls, ['all:1', 'article:1', 'new:1']);
    expect(find.text('Yeni tanıştığın kelime yok.'), findsOneWidget);
    expect(find.text('Koffer'), findsNothing);
  });

  testWidgets('Yükleme hatasında yeniden deneme çalışır', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _UserService()..fail = true;
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<UserService>.value(value: service),
        Provider<PronunciationService>.value(value: _PronunciationService()),
      ],
      child: const MaterialApp(home: WordCollectionScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Kelimeler yüklenemedi. Tekrar deneyebilirsin.'),
        findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('TEKRAR DENE'));
    await tester.pumpAndSettle();
    expect(find.text('Koffer'), findsOneWidget);
  });

  testWidgets('Hoparlör ortak butonla basılır ve ses sürerken dalgalanır',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final audio = _PronunciationService();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<UserService>.value(value: _UserService()),
        Provider<PronunciationService>.value(value: audio),
      ],
      child: const MaterialApp(home: WordCollectionScreen()),
    ));
    await tester.pumpAndSettle();

    final speakerButton = find.byType(KartySoundButton);
    expect(speakerButton, findsOneWidget);
    expect(
        find.descendant(
            of: speakerButton, matching: find.byType(DepthPressableButton)),
        findsOneWidget);
    final speakerPress =
        await tester.startGesture(tester.getCenter(speakerButton));
    await tester.pump(const Duration(milliseconds: 150));
    final speakerFace = find.descendant(
        of: speakerButton, matching: find.byType(AnimatedPositioned));
    expect(tester.widget<AnimatedPositioned>(speakerFace).top, greaterThan(0));
    await speakerPress.cancel();
    await tester.tap(speakerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final speakerMark =
        find.descendant(of: speakerButton, matching: find.byType(SpeakerMark));
    expect(tester.widget<SpeakerMark>(speakerMark).wave, greaterThan(0));

    await tester.tap(speakerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(audio._playbacks.length, 2);
    expect(tester.widget<SpeakerMark>(speakerMark).wave, greaterThan(0));

    audio.finish(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<SpeakerMark>(speakerMark).wave, greaterThan(0));

    audio.finish();
    await tester.pump();
    await tester.pump();
    expect(tester.widget<SpeakerMark>(speakerMark).wave, 0);

    await tester.tap(speakerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(audio._playbacks.length, 3);
    expect(tester.widget<SpeakerMark>(speakerMark).wave, greaterThan(0));
    audio.finish();
    await tester.pump();
  });
}
