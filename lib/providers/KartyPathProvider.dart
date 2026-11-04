import 'package:flutter/foundation.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/services/KartyService.dart';

enum KartyPathStatus { loading, ready, error }

/// Karty Yolu'nun verisi. `QuestsProvider` deseni: ağ hatası ekranı bozmaz,
/// eldeki son veriyle devam edilir (§3.1).
class KartyPathProvider extends ChangeNotifier {
  KartyPathProvider(this._service);

  final KartyService _service;

  KartyPathStatus status = KartyPathStatus.loading;
  KartyPathResponse? data;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      status = KartyPathStatus.loading;
      notifyListeners();
    }

    try {
      final response = await _service.path();
      if (response.data != null) {
        data = response.data;
        status = KartyPathStatus.ready;
      } else if (data == null) {
        status = KartyPathStatus.error;
      }
    } catch (_) {
      if (data == null) status = KartyPathStatus.error;
    }
    notifyListeners();
  }
}
