/// Hesap silmenin sonucu.
enum AccountDeletionResult {
  /// Hesap ve bütün verisi silindi.
  deleted,

  /// Hesap Apple ile bağlı: sunucu silmeden önce Apple'ın onayını (tek
  /// kullanımlık yetki kodunu) istiyor, E4130.
  appleConsentRequired,

  /// Apple penceresi kapatıldı ya da onay alınamadı; hesap silinmedi.
  appleConsentCanceled,

  /// Sunucu reddetti; hesap silinmedi.
  failed,
}

/// `DELETE users/{id}/account`; bkz. `UserService.deleteAccount`.
typedef AccountDeleteRequest = Future<AccountDeletionResult> Function({
  String? appleAuthorizationCode,
  bool skipAppleRevocation,
});

/// Hesap silme akışı. Apple ile bağlı hesapta sunucu önce Apple'ın onayını
/// ister: iOS'ta Apple penceresi açılır, alınan tek kullanımlık kodla silme
/// yeniden gönderilir ve sunucu bu kodla Apple'daki izni geri alır (App
/// Store 5.1.1(v)). Apple penceresi olmayan platformda (Android) hesap,
/// Apple'daki izin geri alınmadan silinir. Bağlantı hatası olduğu gibi
/// yükselir.
Future<AccountDeletionResult> deleteAccountWithAppleConsent({
  required AccountDeleteRequest delete,
  required Future<String?> Function() appleAuthorizationCode,
  required bool appleAvailable,
}) async {
  final first = await delete();
  if (first != AccountDeletionResult.appleConsentRequired) return first;

  if (!appleAvailable) {
    return _settled(await delete(skipAppleRevocation: true));
  }
  final code = await appleAuthorizationCode();
  if (code == null) return AccountDeletionResult.appleConsentCanceled;
  return _settled(await delete(appleAuthorizationCode: code));
}

/// İkinci istekte sunucu yine onay isterse hesap silinmemiştir.
AccountDeletionResult _settled(AccountDeletionResult result) =>
    result == AccountDeletionResult.appleConsentRequired
        ? AccountDeletionResult.failed
        : result;
