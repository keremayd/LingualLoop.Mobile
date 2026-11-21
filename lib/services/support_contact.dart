import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Destek adresi; stelinda.com/destek ve yasal metinlerdekiyle aynı.
abstract final class SupportContact {
  static const email = 'destek@stelinda.com';

  /// E-posta uygulamasında [subject] konulu bir taslak açar. Açılamazsa
  /// (cihazda e-posta uygulaması yoksa) adresi panoya kopyalar ve `false`
  /// döner.
  static Future<bool> compose({required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      // `queryParameters` boşluğu "+" yapıyor, e-posta uygulamaları da onu
      // konuda olduğu gibi gösteriyor.
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    try {
      if (await launchUrl(uri)) return true;
    } catch (error) {
      if (kDebugMode) debugPrint('E-posta uygulaması açılamadı: $error');
    }
    await Clipboard.setData(const ClipboardData(text: email));
    return false;
  }
}
