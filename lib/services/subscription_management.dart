import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abonelik mağazada yönetilir (iptal, yenileme, ödeme yöntemi); uygulama
/// yalnız mağazanın abonelik sayfasını açar. İki adres de mağazaların
/// belgelediği sayfa: iOS App Store adresini doğrudan App Store'da açar.
abstract final class SubscriptionManagement {
  static final appStore =
      Uri.parse('https://apps.apple.com/account/subscriptions');
  static final googlePlay =
      Uri.parse('https://play.google.com/store/account/subscriptions');

  static Uri get page =>
      defaultTargetPlatform == TargetPlatform.android ? googlePlay : appStore;

  /// Sayfa açılamazsa `false` döner.
  static Future<bool> open() async {
    try {
      return await launchUrl(page, mode: LaunchMode.externalApplication);
    } catch (error) {
      if (kDebugMode) debugPrint('Abonelik sayfası açılamadı: $error');
      return false;
    }
  }
}
