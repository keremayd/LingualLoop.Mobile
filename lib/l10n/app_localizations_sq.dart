// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get leagueMerkur => 'Mërkuri';

  @override
  String get leagueAytasi => 'Guri i Hënës';

  @override
  String get leagueYildiz => 'Ylli';

  @override
  String get leagueKuyruklu => 'Kometa';

  @override
  String get leagueMars => 'Marsi';

  @override
  String get leagueUranus => 'Urani';

  @override
  String get leagueSaturn => 'Saturni';

  @override
  String get leagueNebula => 'Mjegullnaja';

  @override
  String get leagueKosmoz => 'Kozmosi';

  @override
  String get leagueSupernova => 'Supernova';

  @override
  String get leaguePulsar => 'Pulsari';

  @override
  String pathDeck(int number) {
    return 'Pako $number';
  }

  @override
  String get pathReview => 'Përsëritje';

  @override
  String pathUnlockHint(int unit, String unitSuffix, int percent) {
    return 'Hapet kur përforcohet $percent% e Njësisë $unit';
  }

  @override
  String unitUnlockReason(int unit, String unitSuffix, int percent) {
    return 'E përforcove $percent% të Njësisë $unit.';
  }
}
