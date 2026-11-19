import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Arayüz metinlerine kısa yol: `context.l10n.pathReview`.
///
/// Metinler `lib/l10n/*.arb` dosyalarında; kaynak Türkçe (`app_tr.arb`),
/// her anahtar önce oraya yazılır. Dil seçimi `AppLanguage`.
extension AppLocalizationsContext on BuildContext {
  /// Ekranın dilindeki metinler. Yerelleştirme kurulmamış bir ağaçta
  /// (önizleme testleri `MaterialApp`'i delegesiz kuruyor) Türkçe döner;
  /// böylece testler ve golden'lar değişmeden çalışır.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      turkishLocalizations;
}

/// Bağlamı olmayan yerler ve testler için kaynak dil.
final AppLocalizations turkishLocalizations =
    lookupAppLocalizations(const Locale('tr'));
