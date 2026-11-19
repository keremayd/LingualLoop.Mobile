import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kullanıcının ana dili: arayüzün, ünite adlarının ve kart anlamlarının
/// dili. Öğrenilen dil her zaman Almanca (16 Kas 2026: Türkçe ve Arnavutça).
///
/// Seçim cihazda saklanır ve her isteğe `Accept-Language` başlığıyla gider
/// (`TokenInterceptor`); sunucu ünite adını, kart anlamını ve görev
/// başlığını bu dilde döner (`LocaleRules`, aynı kural: desteklenmeyen dil
/// Türkçe sayılır). Seçim yoksa cihazın dili desteklenen bir dilse o,
/// değilse Türkçe.
class AppLanguage extends ChangeNotifier {
  AppLanguage(String code, {this.chosen = false})
      : _code = normalize(code) ?? defaultCode {
    current = _code;
  }

  /// Cihazın dili desteklenmiyorsa ve seçim yoksa. Sunucudaki
  /// `LocaleRules.Default` ile aynı.
  static const String defaultCode = 'tr';
  static const List<String> supported = ['tr', 'sq'];

  /// Seçicide her dil kendi adıyla yazılır.
  static const Map<String, String> endonyms = {'tr': 'Türkçe', 'sq': 'Shqip'};

  static const String _storageKey = 'nativeLanguage';

  /// Son seçilen dil. İstek başlığı widget ağacının dışında kuruluyor
  /// (interceptor), oradan okunur.
  static String current = defaultCode;

  String _code;

  /// Kullanıcı dili kendisi seçti mi (yoksa cihazdan tahmin edildi).
  bool chosen;

  String get code => _code;
  Locale get locale => Locale(_code);

  /// Desteklenen dil kodu ("sq", "SQ", "sq-XK", "sq_AL" → "sq"); değilse null.
  static String? normalize(String? code) {
    if (code == null) return null;
    final primary = code.trim().split(RegExp('[-_]')).first.toLowerCase();
    return supported.contains(primary) ? primary : null;
  }

  static Future<AppLanguage> load({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    List<Locale>? deviceLocales,
  }) async {
    String? saved;
    try {
      saved = normalize(await storage.read(key: _storageKey));
    } catch (_) {
      // Okunamazsa cihazın dili; seçim bir sonraki kayıtta düzelir.
    }
    if (saved != null) return AppLanguage(saved, chosen: true);

    final device = (deviceLocales ??
            WidgetsBinding.instance.platformDispatcher.locales)
        .map((locale) => normalize(locale.languageCode))
        .whereType<String>()
        .firstOrNull;
    return AppLanguage(device ?? defaultCode);
  }

  Future<void> select(
    String code, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    final next = normalize(code);
    if (next == null) return;
    chosen = true;
    if (next != _code) {
      _code = next;
      current = next;
      notifyListeners();
    }
    try {
      await storage.write(key: _storageKey, value: next);
    } catch (_) {
      // Yazılamazsa seçim bu oturumda geçerli kalır.
    }
  }
}
