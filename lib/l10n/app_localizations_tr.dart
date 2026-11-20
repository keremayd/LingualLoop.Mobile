// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get accountDeletionAppleCanceled =>
      'Apple onayı alınamadı, hesap silinmedi.';

  @override
  String get leagueMerkur => 'Merkür';

  @override
  String get leagueAytasi => 'Aytaşı';

  @override
  String get leagueYildiz => 'Yıldız';

  @override
  String get leagueKuyruklu => 'Kuyruklu';

  @override
  String get leagueMars => 'Mars';

  @override
  String get leagueUranus => 'Uranüs';

  @override
  String get leagueSaturn => 'Satürn';

  @override
  String get leagueNebula => 'Nebula';

  @override
  String get leagueKosmoz => 'Kosmoz';

  @override
  String get leagueSupernova => 'Supernova';

  @override
  String get leaguePulsar => 'Pulsar';

  @override
  String pathDeck(int number) {
    return 'Deste $number';
  }

  @override
  String get pathReview => 'Tekrar';

  @override
  String pathUnlockHint(int unit, String unitSuffix, int percent) {
    return 'Ünite $unit$unitSuffix %$percent\'i pekişince açılır';
  }

  @override
  String unitUnlockReason(int unit, String unitSuffix, int percent) {
    return 'Ünite $unit$unitSuffix %$percent\'ini pekiştirdin.';
  }

  @override
  String get leagueMemberReport => 'Bildir';

  @override
  String get leagueMemberBlock => 'Engelle';

  @override
  String get leagueMemberCancel => 'Vazgeç';

  @override
  String get leagueReportTitle => 'Neden bildiriyorsun?';

  @override
  String get leagueReportReasonName => 'Uygunsuz ad';

  @override
  String get leagueReportReasonPhoto => 'Uygunsuz fotoğraf';

  @override
  String get leagueReportReasonOther => 'Başka bir sebep';

  @override
  String get leagueReportSent => 'Bildirimin alındı, incelenecek.';

  @override
  String leagueBlockTitle(String name) {
    return '$name engellensin mi?';
  }

  @override
  String get leagueBlockBody => 'Sıralamada artık birbirinizi görmezsiniz.';

  @override
  String leagueBlockDone(String name) {
    return '$name engellendi.';
  }

  @override
  String get leagueModerationFailed =>
      'Gönderilemedi. Bağlantını kontrol edip tekrar dene.';

  @override
  String leagueMemberOptions(String name) {
    return '$name için seçenekler';
  }
}
