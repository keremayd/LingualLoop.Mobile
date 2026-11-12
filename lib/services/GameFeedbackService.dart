import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lingualloop/services/PronunciationService.dart';

enum _GameSound {
  correct('assets/sounds/correct.wav'),
  wrong('assets/sounds/wrong.wav'),
  complete('assets/sounds/complete.wav');

  const _GameSound(this.asset);

  final String asset;
}

/// Oyunun cevap anlarındaki kısa ses ve titreşim.
///
/// Ses, oyundaki hoparlör düğmesine uyar: kullanıcıya telaffuzdan ayrı ikinci
/// bir ses ayarı gösterilmez. Titreşim ona bağlı değil, sessiz oynayan da
/// cevabı elinde hisseder; ayarlar penceresinden ayrıca kapatılır.
///
/// Her ses kendi oynatıcısında: telaffuz ve art arda gelen efektler birbirini
/// kesmez.
class GameFeedbackService {
  GameFeedbackService(
    this._pronunciation, {
    AudioPlayer Function()? createPlayer,
    FlutterSecureStorage? storage,
  })  : _createPlayer = createPlayer ?? AudioPlayer.new,
        _storage = storage ?? const FlutterSecureStorage() {
    unawaited(_restoreVibration());
  }

  static const vibrationPreferenceKey = 'game_vibration_enabled';

  final PronunciationService _pronunciation;
  final AudioPlayer Function() _createPlayer;
  final FlutterSecureStorage _storage;
  final Map<_GameSound, Future<AudioPlayer>> _players = {};

  /// Varsayılan açık. Kayıtlı tercih okunmadan kullanıcı değiştirdiyse onun
  /// seçimi kalır.
  final ValueNotifier<bool> vibrationEnabled = ValueNotifier(true);
  bool _vibrationChosen = false;

  Future<void> _restoreVibration() async {
    try {
      final stored = await _storage.read(key: vibrationPreferenceKey);
      if (stored != null && !_vibrationChosen) {
        vibrationEnabled.value = stored == 'true';
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Titreşim tercihi okunamadı: $error');
    }
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationChosen = true;
    vibrationEnabled.value = enabled;
    try {
      await _storage.write(key: vibrationPreferenceKey, value: '$enabled');
    } catch (error) {
      if (kDebugMode) debugPrint('Titreşim tercihi kaydedilemedi: $error');
    }
  }

  void _vibrate(Future<void> Function() impact) {
    if (vibrationEnabled.value) unawaited(impact());
  }

  Future<AudioPlayer> _playerFor(_GameSound sound) {
    return _players[sound] ??= () async {
      final player = _createPlayer();
      await player.setAsset(sound.asset);
      return player;
    }();
  }

  /// Oyun açılırken çağrılır; ilk cevabın sesi geç kalmasın.
  Future<void> preload() async {
    try {
      await Future.wait(_GameSound.values.map(_playerFor));
    } catch (error) {
      if (kDebugMode) debugPrint('Oyun sesleri yüklenemedi: $error');
    }
  }

  Future<void> _play(_GameSound sound) async {
    if (_pronunciation.isMuted.value) return;
    try {
      await _pronunciation.ensureAudioSession();
      final player = await _playerFor(sound);
      // just_audio bitince `playing` true kalıyor; durdurulmazsa play() hemen
      // döner ve ses çalmaz.
      if (player.playing) await player.pause();
      await player.seek(Duration.zero);
      await player.play();
    } catch (error) {
      if (kDebugMode) debugPrint('Oyun sesi çalınamadı: $error');
    }
  }

  void correct() {
    _vibrate(HapticFeedback.lightImpact);
    unawaited(_play(_GameSound.correct));
  }

  void wrong() {
    _vibrate(HapticFeedback.heavyImpact);
    unawaited(_play(_GameSound.wrong));
  }

  /// Deste ya da Rövanş bitti.
  void complete() {
    _vibrate(HapticFeedback.mediumImpact);
    unawaited(_play(_GameSound.complete));
  }

  Future<void> dispose() async {
    vibrationEnabled.dispose();
    final players = await Future.wait(_players.values);
    await Future.wait(players.map((player) => player.dispose()));
  }
}
