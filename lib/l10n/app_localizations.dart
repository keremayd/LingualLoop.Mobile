import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_sq.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('sq'),
    Locale('tr')
  ];

  /// Hesap silme penceresinde: Apple ile bağlı hesapta Apple penceresi kapatıldı ya da onay vermedi.
  ///
  /// In tr, this message translates to:
  /// **'Apple onayı alınamadı, hesap silinmedi.'**
  String get accountDeletionAppleCanceled;

  /// No description provided for @leagueMerkur.
  ///
  /// In tr, this message translates to:
  /// **'Merkür'**
  String get leagueMerkur;

  /// No description provided for @leagueAytasi.
  ///
  /// In tr, this message translates to:
  /// **'Aytaşı'**
  String get leagueAytasi;

  /// No description provided for @leagueYildiz.
  ///
  /// In tr, this message translates to:
  /// **'Yıldız'**
  String get leagueYildiz;

  /// No description provided for @leagueKuyruklu.
  ///
  /// In tr, this message translates to:
  /// **'Kuyruklu'**
  String get leagueKuyruklu;

  /// No description provided for @leagueMars.
  ///
  /// In tr, this message translates to:
  /// **'Mars'**
  String get leagueMars;

  /// No description provided for @leagueUranus.
  ///
  /// In tr, this message translates to:
  /// **'Uranüs'**
  String get leagueUranus;

  /// No description provided for @leagueSaturn.
  ///
  /// In tr, this message translates to:
  /// **'Satürn'**
  String get leagueSaturn;

  /// No description provided for @leagueNebula.
  ///
  /// In tr, this message translates to:
  /// **'Nebula'**
  String get leagueNebula;

  /// No description provided for @leagueKosmoz.
  ///
  /// In tr, this message translates to:
  /// **'Kosmoz'**
  String get leagueKosmoz;

  /// No description provided for @leagueSupernova.
  ///
  /// In tr, this message translates to:
  /// **'Supernova'**
  String get leagueSupernova;

  /// No description provided for @leaguePulsar.
  ///
  /// In tr, this message translates to:
  /// **'Pulsar'**
  String get leaguePulsar;

  /// Patikadaki deste düğmesinin adı.
  ///
  /// In tr, this message translates to:
  /// **'Deste {number}'**
  String pathDeck(int number);

  /// Açık bütün desteler bitince patikadaki yalnız tekrar adımı.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get pathReview;

  /// Kilitli ünitenin başlığında. unitSuffix Türkçe ilgi hâli eki (1'in, 2'nin); başka dil kullanmaz.
  ///
  /// In tr, this message translates to:
  /// **'Ünite {unit}{unitSuffix} %{percent}\'i pekişince açılır'**
  String pathUnlockHint(int unit, String unitSuffix, int percent);

  /// Ünite açılış kutlamasında, kilidi açan önceki ünite. unitSuffix yalnız Türkçede.
  ///
  /// In tr, this message translates to:
  /// **'Ünite {unit}{unitSuffix} %{percent}\'ini pekiştirdin.'**
  String unitUnlockReason(int unit, String unitSuffix, int percent);

  /// Sıralamada başka birine dokununca: kişiyi bildir (App Store 1.2).
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get leagueMemberReport;

  /// Sıralamada başka birine dokununca: kişiyi engelle; onay düğmesi de bu.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get leagueMemberBlock;

  /// Bildir/engelle penceresini kapatır.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get leagueMemberCancel;

  /// Bildirim sebebi seçimi başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Neden bildiriyorsun?'**
  String get leagueReportTitle;

  /// No description provided for @leagueReportReasonName.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz ad'**
  String get leagueReportReasonName;

  /// No description provided for @leagueReportReasonPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz fotoğraf'**
  String get leagueReportReasonPhoto;

  /// No description provided for @leagueReportReasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir sebep'**
  String get leagueReportReasonOther;

  /// Bildirim gönderilince çıkan mesaj.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimin alındı, incelenecek.'**
  String get leagueReportSent;

  /// Engel onayı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellensin mi?'**
  String leagueBlockTitle(String name);

  /// No description provided for @leagueBlockBody.
  ///
  /// In tr, this message translates to:
  /// **'Sıralamada artık birbirinizi görmezsiniz.'**
  String get leagueBlockBody;

  /// Engel kaydedilince çıkan mesaj.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellendi.'**
  String leagueBlockDone(String name);

  /// No description provided for @leagueModerationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilemedi. Bağlantını kontrol edip tekrar dene.'**
  String get leagueModerationFailed;

  /// Ekran okuyucu: sıralamadaki satıra dokununca seçenekler açılır.
  ///
  /// In tr, this message translates to:
  /// **'{name} için seçenekler'**
  String leagueMemberOptions(String name);

  /// Premium ürünleri App Store'dan alınamayınca.
  ///
  /// In tr, this message translates to:
  /// **'Mağazaya şu an ulaşılamıyor. Biraz sonra tekrar dene.'**
  String get premiumStoreUnavailable;

  /// No description provided for @premiumWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a hoş geldin! Biletlerin artık sınırsız.'**
  String get premiumWelcome;

  /// No description provided for @premiumPurchaseFailed.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı. Tekrar dene.'**
  String get premiumPurchaseFailed;

  /// Ask to Buy gibi onay bekleyen satın alma.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma onay bekliyor; onaylanınca Premium açılır.'**
  String get premiumPurchasePending;

  /// No description provided for @premiumNothingToRestore.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenecek etkin bir abonelik bulunamadı.'**
  String get premiumNothingToRestore;

  /// No description provided for @premiumActiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium üyeliğin aktif'**
  String get premiumActiveTitle;

  /// No description provided for @premiumActiveBody.
  ///
  /// In tr, this message translates to:
  /// **'Biletlerin sınırsız, seri korumaların her hafta ikiye dolar.'**
  String get premiumActiveBody;

  /// No description provided for @premiumManage.
  ///
  /// In tr, this message translates to:
  /// **'ABONELİĞİ YÖNET'**
  String get premiumManage;

  /// No description provided for @premiumActiveClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get premiumActiveClose;

  /// No description provided for @premiumManageFailed.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik sayfası açılamadı. Tekrar dene.'**
  String get premiumManageFailed;

  /// Ekran okuyucu: premium üyenin bilet sayacı (∞).
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız bilet'**
  String get ticketsUnlimited;

  /// Hesap silme penceresi, premium üyede: abonelik hesapla birlikte iptal edilmez (Apple'ın hesap silme yönergesi).
  ///
  /// In tr, this message translates to:
  /// **'Premium abonelik hesapla birlikte iptal edilmez. Ödemenin durması için abonelik App Store\'dan ayrıca iptal edilmelidir.'**
  String get accountDeletionSubscriptionNote;

  /// Hesap silme penceresinde App Store abonelik sayfasını açan bağlantı.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliği yönet'**
  String get accountDeletionManageSubscription;

  /// Girişte "Parolamı unuttum"a dokununca açılan pencerenin başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni mi unuttun?'**
  String get passwordHelpTitle;

  /// Şifre penceresinin açıklaması; altında destek adresi ayrı satırda durur.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı yakında uygulamaya eklenecek. O zamana kadar hesapta kayıtlı e-posta adresinden destek adresine yazılabilir:'**
  String get passwordHelpBody;

  /// E-posta uygulamasında destek adresine taslak açan düğme.
  ///
  /// In tr, this message translates to:
  /// **'DESTEĞE YAZ'**
  String get passwordHelpWrite;

  /// Destek e-postası taslağının konusu.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama'**
  String get passwordHelpMailSubject;

  /// E-posta uygulaması açılamayınca adres panoya kopyalanır.
  ///
  /// In tr, this message translates to:
  /// **'E-posta uygulaması açılamadı; adres kopyalandı.'**
  String get passwordHelpCopied;

  /// No description provided for @passwordHelpClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get passwordHelpClose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['sq', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'sq':
      return AppLocalizationsSq();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
