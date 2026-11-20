// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get accountDeletionAppleCanceled =>
      'Miratimi i Apple nuk u mor, llogaria nuk u fshi.';

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

  @override
  String get leagueMemberReport => 'Raporto';

  @override
  String get leagueMemberBlock => 'Blloko';

  @override
  String get leagueMemberCancel => 'Anulo';

  @override
  String get leagueReportTitle => 'Pse po e raporton?';

  @override
  String get leagueReportReasonName => 'Emër i papërshtatshëm';

  @override
  String get leagueReportReasonPhoto => 'Foto e papërshtatshme';

  @override
  String get leagueReportReasonOther => 'Arsye tjetër';

  @override
  String get leagueReportSent => 'Raportimi u mor dhe do të shqyrtohet.';

  @override
  String leagueBlockTitle(String name) {
    return 'Të bllokohet $name?';
  }

  @override
  String get leagueBlockBody =>
      'Nuk do ta shihni më njëri-tjetrin në renditje.';

  @override
  String leagueBlockDone(String name) {
    return '$name u bllokua.';
  }

  @override
  String get leagueModerationFailed =>
      'Nuk u dërgua. Kontrollo lidhjen dhe provo sërish.';

  @override
  String leagueMemberOptions(String name) {
    return 'Opsione për $name';
  }
}
