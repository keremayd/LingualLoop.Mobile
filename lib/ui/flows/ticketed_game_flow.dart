import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/UpdateLivesResponse.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/Popups/out_of_tickets_popup.dart';
import 'package:lingualloop/ui/widgets/ticket_spend_scene.dart';
import 'package:provider/provider.dart';

/// Biletin yetmediği durumda sunucu E4116 döndürür ve oyun açılmaz.
const _noLivesErrorCode = 'E4116';

/// Oyuna giriş bedeli olan bileti harcar; harcandıysa `true`.
///
/// Karty'nin DEVAM'ı ve Artikel durağı aynı yoldan geçer. Bilet yetmezse
/// "bilet bitti" penceresi açılır ve `false` döner; pencerenin Rövanş ve
/// Görevler yolları geri çağrı olarak alınır. Bedel yolda yazmadığı için
/// harcama [playEntrance] sahnesiyle gösterilir; bilet düğüme girince döner.
Future<bool> spendTicketForGame(
  BuildContext context, {
  required TicketSpendPlayback Function() playEntrance,
  required VoidCallback onGoToReview,
  required VoidCallback onGoToQuests,
}) async {
  final userService = Provider.of<UserService>(context, listen: false);
  final scoreProvider = context.read<ScoreWithLivesProvider>();

  // Sayaç dokunur dokunmaz düşer ve sahne başlar, sunucu beklenmez;
  // reddedilirse sahne kalkar, sayaç geri gelir.
  final before = scoreProvider.scoreWithLives?.lives ?? 0;
  final entrance = before > 0 ? playEntrance() : null;
  if (before > 0) scoreProvider.setLives(before - 1);

  final ApiResponse<UpdateLivesResponse> apiResponse;
  try {
    apiResponse = await userService.updateLivesById();
  } catch (_) {
    entrance?.cancel();
    scoreProvider.setLives(before);
    rethrow;
  }
  if (apiResponse.errorCode == null) {
    final remaining = apiResponse.data?.lives;
    if (remaining != null) scoreProvider.setLives(remaining);
    await entrance?.arrived;
    return true;
  }
  entrance?.cancel();

  // Giriş reddedildi. Bilet duvarı düz bir uyarı mesajı değil, kendi
  // penceresini hak ediyor: kullanıcıya neden oynayamadığını, ne zaman
  // oynayabileceğini ve beklemek istemiyorsa ne olduğunu birlikte anlatır.
  if (apiResponse.errorCode != _noLivesErrorCode) {
    scoreProvider.setLives(before);
    AppNotifier.showMessage('Oyun açılamadı. Daha sonra tekrar dene.');
    return false;
  }

  // Geri sayımı doğru gösterebilmek için önce güncel bileti çek.
  if (!context.mounted) return false;
  await userService.scoreWithLivesById(context);
  if (!context.mounted) return false;

  // Popup, yolların yalnız adını değil o anki gerçek değerini gösterir:
  // bekleyen Rövanş yoksa yol pasifleşir; görev satırında bugün hâlâ
  // kazanılabilecek toplam bilet görünür.
  final questsProvider = context.read<QuestsProvider>();
  final profileStatsProvider = context.read<ProfileLearningStatsProvider>();
  await Future.wait([
    questsProvider.load(silent: questsProvider.data != null),
    profileStatsProvider.refreshFromService(userService),
  ]);
  if (!context.mounted) return false;

  final questTickets = questsProvider.data?.quests
      .where((quest) => !quest.isClaimed)
      .fold<int>(0, (total, quest) => total + quest.rewardTickets);
  final reviewAvailable =
      (profileStatsProvider.stats?.reviewPendingCount ?? 0) > 0;

  await showOutOfTicketsPopup(
    context,
    nextTicketAt: scoreProvider.scoreWithLives?.nextTicketAt,
    onRefreshTickets: () async {
      if (!context.mounted) return false;
      final refreshed = await userService.scoreWithLivesById(context);
      return (refreshed.data?.lives ?? 0) > 0;
    },
    questTickets: questTickets,
    reviewAvailable: reviewAvailable,
    onGoToReview: onGoToReview,
    onGoToQuests: onGoToQuests,
    onGoPremium: () {
      // Premium akışı henüz yok; niyet kaydı burada duruyor ki pencere
      // hazır olduğunda tek yerden bağlansın.
      AppNotifier.showMessage('Premium yakında!');
    },
  );
  return false;
}
