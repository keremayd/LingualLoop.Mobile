import 'dart:async';

import 'package:stelinda/services/premium_store.dart';

/// Bütün testlerden önce çalışır. Testler varsayılan olarak Android gibi
/// çalışıyor; satın alma şimdilik yalnız iOS'ta olduğu için premium girişleri
/// orada gizli. Önizlemeler uygulamanın iOS'taki hâlini çizsin.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PremiumStore.debugSupportedOverride = true;
  await testMain();
}
