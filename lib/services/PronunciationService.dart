import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';

/// Karty kelimelerinin Almanca telaffuzunu çalar.
///
/// ## Neden cihaz TTS'i değil
///
/// `flutter_tts` denendi ve bırakıldı: ses kalitesi cihazdan cihaza değişiyor
/// ve Android'de kullanıcının hangi dil paketini indirdiğine bağlı. Telaffuz
/// öğretmeye çalışan bir uygulamada "cihaza göre değişen ses" kabul edilemez.
///
/// Sesler artık sunucuda **önceden üretiliyor** (Amazon Polly, `de-DE`,
/// neural `Vicki`) ve S3'ten imzalı URL ile geliyor. Her kullanıcı aynı sesi
/// duyuyor.
///
/// ## Tek oynatıcı
///
/// Sınıf tek bir `AudioPlayer` tutuyor. Her çalmada yenisi kurulsaydı üst
/// üste basıldığında sesler çakışır ve iki kelime aynı anda duyulurdu;
/// tek oynatıcıda yeni kaynak öncekini kendiliğinden kesiyor.
class PronunciationService {
  PronunciationService({
    AudioPlayer? player,
    FlutterSecureStorage? storage,
    Future<void> Function()? configureSession,
  })  : _player = player ?? AudioPlayer(),
        _storage = storage ?? const FlutterSecureStorage(),
        _configureSession = configureSession {
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (_disposed) return;
      isSpeaking.value = !isMuted.value &&
          state.playing &&
          state.processingState == ProcessingState.ready;
    });
    ready = _restorePreference();
  }

  static const mutePreferenceKey = 'karty_pronunciation_muted';
  final AudioPlayer _player;
  final FlutterSecureStorage _storage;
  final Future<void> Function()? _configureSession;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final Future<void> ready;
  final ValueNotifier<bool> isMuted = ValueNotifier(true);
  Future<void> _saveQueue = Future<void>.value();
  int _preferenceVersion = 0;
  int _requestVersion = 0;
  bool _disposed = false;

  Future<void> _restorePreference() async {
    final version = _preferenceVersion;
    try {
      final stored = await _storage.read(key: mutePreferenceKey);
      if (!_disposed && version == _preferenceVersion) {
        isMuted.value = stored == 'true';
      }
    } catch (error) {
      // If the saved choice cannot be read, stay quiet until the user opts in.
      if (kDebugMode) debugPrint('Ses tercihi okunamadı: $error');
    }
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    _preferenceVersion++;
    _requestVersion++;
    isMuted.value = muted;
    final stopping = muted ? stop() : Future<void>.value();
    // Serialize writes so quick off/on taps persist the final choice.
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _storage.write(key: mutePreferenceKey, value: '$muted');
      } catch (error) {
        if (kDebugMode) debugPrint('Ses tercihi kaydedilemedi: $error');
      }
    });
    await Future.wait([stopping, _saveQueue]);
  }

  /// Ses **şu anda** çalıyor mu. Arayüz bunu izleyerek animasyonunu sesin
  /// gerçek süresine bağlıyor; sabit bir süre kısa kelimede uzun, uzun
  /// kelimede kısa kalırdı.
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  /// Ses oturumu bir kez kuruluyor.
  ///
  /// **Bu olmadan iOS'ta ses çıkmıyor.** Varsayılan kategori ortam sesi
  /// (`ambient`) gibi davranıyor ve cihazın sessiz anahtarı onu kesiyor.
  /// Telaffuz burada bir efekt değil **içeriğin kendisi** — kullanıcı
  /// telefonunu sessizde tutuyor diye kelimeyi duyamamalı, o yüzden
  /// kategori `playback`.
  Future<void>? _sessionSetup;

  Future<void> _ensureSession() {
    return _sessionSetup ??= () async {
      if (_configureSession != null) {
        await _configureSession();
        return;
      }
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
    }();
  }

  /// Aynı URL için tekrar tekrar `setUrl` çağırmamak adına son çalınan
  /// kaynağı hatırlıyor: aynı kartta butona ikinci kez basmak ağ isteği
  /// değil, baştan oynatma olmalı.
  String? _loadedUrl;

  bool _canPlay(int version) =>
      !_disposed && !isMuted.value && version == _requestVersion;

  /// The saved preference is loaded before the first sound. A generation
  /// check after every await invalidates queued speech on mute or navigation,
  /// including a second request for the very same URL.
  Future<void> play(String? url) async {
    if (_disposed || url == null || url.isEmpty) return;
    final version = ++_requestVersion;
    try {
      await ready;
      if (!_canPlay(version)) return;
      await _ensureSession();
      if (!_canPlay(version)) return;
      if (_loadedUrl != url) {
        await _player.stop();
        if (!_canPlay(version)) return;
        await _player.setUrl(url);
        if (!_canPlay(version)) return;
        _loadedUrl = url;
      } else {
        await _player.seek(Duration.zero);
      }
      if (!_canPlay(version)) return;
      await _player.play();
    } catch (error) {
      if (version == _requestVersion) _loadedUrl = null;
      if (kDebugMode) debugPrint('Telaffuz çalınamadı: $error');
    }
  }

  /// Çalmayı keser. Karty ekranından çıkarken çağrılıyor — servis uygulama
  /// ömrü boyunca yaşadığı için ekran kapansa da oynatıcı kendiliğinden
  /// susmuyor.
  Future<void> stop() async {
    _requestVersion++;
    if (!_disposed) isSpeaking.value = false;
    _loadedUrl = null;
    try {
      await _player.stop();
    } catch (_) {
      // Durdurma hatası akışı etkilemez.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _requestVersion++;
    await _stateSubscription.cancel();
    await _player.dispose();
    isSpeaking.dispose();
    isMuted.dispose();
  }
}
