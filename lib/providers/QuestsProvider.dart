import 'package:flutter/foundation.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/services/QuestService.dart';

enum QuestsStatus { loading, ready, error }

class QuestsProvider extends ChangeNotifier {
  QuestsProvider(this._service);

  final QuestService _service;

  QuestsStatus status = QuestsStatus.loading;
  DailyQuestsResponse? data;
  final Set<String> _claiming = {};

  bool isClaiming(String questKey) => _claiming.contains(questKey);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      status = QuestsStatus.loading;
      notifyListeners();
    }

    try {
      final response = await _service.getDailyQuests();
      data = response.data;
      status = QuestsStatus.ready;
    } catch (_) {
      // Eldeki son veri varsa onu göstermeye devam et.
      if (data == null) status = QuestsStatus.error;
    }
    notifyListeners();
  }

  /// Ödülü talep eder; başarılıysa sunucunun döndürdüğü sonucu verir.
  ///
  /// `rewardTickets` görevin nominal ödülü değil, bakiyeye **gerçekten
  /// eklenen** miktardır: tavana takılan ödül sunucuda kesilir. Kutlama bu
  /// sayıyı gösterir ki tavandayken "+2" deyip hiçbir şey vermesin.
  Future<ClaimQuestResponse?> claim(String questKey) async {
    if (_claiming.contains(questKey)) return null;

    _claiming.add(questKey);
    notifyListeners();

    try {
      final response = await _service.claimReward(questKey);
      final result = response.data;
      if (result != null && result.claimed) {
        final quest = data?.quests
            .where((q) => q.questKey == questKey)
            .firstOrNull;
        quest?.isClaimed = true;
        return result;
      }
      // Tavan yüzünden engellendiyse görev **alınabilir kalıyor**; ekranın
      // bunu kullanıcıya söyleyebilmesi için sonuç yutulmaz.
      if (result != null && result.blockedByCap) return result;

      // Talep kabul edilmediyse (yarış/expire) listeyi tazele.
      await load(silent: true);
      return null;
    } catch (_) {
      return null;
    } finally {
      _claiming.remove(questKey);
      notifyListeners();
    }
  }
}
