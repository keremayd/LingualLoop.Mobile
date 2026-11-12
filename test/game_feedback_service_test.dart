import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/PronunciationService.dart';

class _Player extends Fake implements AudioPlayer {
  _Player(this.log);

  final List<String> log;
  String? asset;

  @override
  bool get playing => false;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    asset = assetPath;
    log.add('yükle $assetPath');
    return null;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> play() async => log.add('çal $asset');

  @override
  Future<void> dispose() async {}
}

class _Pronunciation extends Fake implements PronunciationService {
  _Pronunciation(bool muted) : isMuted = ValueNotifier(muted);

  @override
  final ValueNotifier<bool> isMuted;

  @override
  Future<void> ensureAudioSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;
  late List<String> haptics;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    log = [];
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });

  GameFeedbackService service({required bool muted}) => GameFeedbackService(
        _Pronunciation(muted),
        createPlayer: () => _Player(log),
      );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('doğru cevap sesi çalar ve hafif titreşir', () async {
    service(muted: false).correct();
    await settle();

    expect(log.last, 'çal assets/sounds/correct.wav');
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  test('yanlış cevap ayrı ses ve güçlü titreşim verir', () async {
    service(muted: false).wrong();
    await settle();

    expect(log.last, 'çal assets/sounds/wrong.wav');
    expect(haptics, ['HapticFeedbackType.heavyImpact']);
  });

  test('hoparlör kapalıyken ses yok, titreşim var', () async {
    service(muted: true).correct();
    await settle();

    expect(log, isEmpty);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  test('aynı ses ikinci kez yüklenmez', () async {
    final feedback = service(muted: false);

    feedback.complete();
    await settle();
    feedback.complete();
    await settle();

    expect(log.where((entry) => entry.startsWith('yükle')), hasLength(1));
    expect(log.where((entry) => entry.startsWith('çal')), hasLength(2));
  });
}
