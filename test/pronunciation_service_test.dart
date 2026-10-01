import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingualloop/services/PronunciationService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  PronunciationService service(_Player player,
          {FlutterSecureStorage? storage}) =>
      PronunciationService(
          player: player, storage: storage, configureSession: () async {});

  test('Kaydedilmiş sessiz tercih ilk otomatik sesten önce okunur', () async {
    FlutterSecureStorage.setMockInitialValues(
        {PronunciationService.mutePreferenceKey: 'true'});
    final player = _Player();
    final audio = service(player);
    await audio.play('word.mp3');
    expect(audio.isMuted.value, isTrue);
    expect(player.loads, isEmpty);
    expect(player.plays, 0);
    await audio.dispose();
  });

  test('Ses göstergesi yalnız hazır ve oynayan seste açılır', () async {
    final player = _Player();
    final audio = service(player);
    await audio.ready;
    for (final state in ProcessingState.values) {
      player.states.add(PlayerState(true, state));
      expect(audio.isSpeaking.value, state == ProcessingState.ready,
          reason: '$state');
    }
    player.states.add(PlayerState(false, ProcessingState.ready));
    expect(audio.isSpeaking.value, isFalse);
    await audio.dispose();
  });

  test('Kapatmak çalan sesi hemen durdurur ve sonraki sesleri engeller',
      () async {
    final player = _Player();
    final audio = service(player);
    await audio.play('word.mp3');
    expect(player.plays, 1);
    expect(audio.isSpeaking.value, isTrue);
    final stopCount = player.stops;
    final saving = audio.setMuted(true);
    expect(audio.isSpeaking.value, isFalse);
    expect(player.stops, stopCount + 1);
    await saving;
    await audio.play('next.mp3');
    expect(player.plays, 1);
    expect(player.loads, ['word.mp3']);
    await audio.dispose();
  });

  test('Tercih yeni serviste korunur; açmak eski sesi kendiliğinden oynatmaz',
      () async {
    final first = service(_Player());
    await first.ready;
    await first.setMuted(true);
    await first.dispose();
    final player = _Player();
    final second = service(player);
    await second.ready;
    expect(second.isMuted.value, isTrue);
    await second.setMuted(false);
    expect(player.plays, 0);
    await second.play('word.mp3');
    expect(player.plays, 1);
    await second.dispose();
  });

  test('Yükleme sırasında kapatıp açmak bekleyen eski sesi başlatmaz',
      () async {
    final player = _Player()..loadGate = Completer<Duration?>();
    final audio = service(player);
    final pending = audio.play('same-word.mp3');
    await player.loadStarted.future;
    await audio.setMuted(true);
    await audio.setMuted(false);
    player.loadGate!.complete(const Duration(seconds: 1));
    await pending;
    expect(player.plays, 0);
    await audio.play('same-word.mp3');
    expect(player.plays, 1);
    await audio.dispose();
  });

  test('Tercih okunurken yapılan kullanıcı seçimi eski kayıtla ezilmez',
      () async {
    final storage = _DelayedStorage();
    final audio = service(_Player(), storage: storage);
    await audio.setMuted(true);
    storage.readResult.complete('false');
    await audio.ready;
    expect(audio.isMuted.value, isTrue);
    expect(storage.writes.last, 'true');
    await audio.dispose();
  });

  test('Hızlı aç/kapat dokunuşlarında son tercih kaydedilir', () async {
    final audio = service(_Player());
    await audio.ready;
    await Future.wait(
        [audio.setMuted(true), audio.setMuted(false), audio.setMuted(true)]);
    expect(
        await const FlutterSecureStorage()
            .read(key: PronunciationService.mutePreferenceKey),
        'true');
    expect(audio.isMuted.value, isTrue);
    await audio.dispose();
  });

  test('Sessizde sıraya giren ses açma dokunuşuyla başlamaz', () async {
    final player = _Player();
    final audio = service(player);
    await audio.ready;
    await audio.setMuted(true);
    final pending = audio.play('word.mp3');
    await audio.setMuted(false);
    await pending;
    expect(player.plays, 0);
    await audio.dispose();
  });
}

class _Player extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final loads = <String>[];
  final loadStarted = Completer<void>();
  Completer<Duration?>? loadGate;
  int plays = 0;
  int stops = 0;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Future<Duration?> setUrl(String url,
      {Map<String, String>? headers,
      Duration? initialPosition,
      bool preload = true,
      dynamic tag}) async {
    loads.add(url);
    if (!loadStarted.isCompleted) loadStarted.complete();
    return loadGate == null
        ? const Duration(seconds: 1)
        : await loadGate!.future;
  }

  @override
  Future<void> play() async {
    plays++;
    states.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    stops++;
    states.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}
  @override
  Future<void> dispose() => states.close();
}

class _DelayedStorage extends Fake implements FlutterSecureStorage {
  final readResult = Completer<String?>();
  final writes = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) return readResult.future;
    if (invocation.memberName == #write) {
      writes.add(invocation.namedArguments[#value] as String);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
