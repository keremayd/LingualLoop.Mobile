import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/Popups/out_of_tickets_popup.dart';
import 'package:provider/provider.dart';

/// Biletin yetmediği durumda sunucu E4116 döndürür ve oyun açılmaz.
const _noLivesErrorCode = 'E4116';

/// Oyuna giriş bedeli olan bileti harcar; harcandıysa `true`.
///
/// Karty'nin DEVAM'ı ve Artikel durağı aynı yoldan geçer. Bilet yetmezse
/// "bilet bitti" penceresi açılır ve `false` döner; pencerenin Rövanş ve
/// Görevler yolları geri çağrı olarak alınır.
Future<bool> spendTicketForGame(
  BuildContext context, {
  required VoidCallback onGoToReview,
  required VoidCallback onGoToQuests,
}) async {
  final userService = Provider.of<UserService>(context, listen: false);

  final apiResponse = await userService.updateLivesById();
  if (apiResponse.errorCode == null) return true;

  // Giriş reddedildi. Bilet duvarı düz bir uyarı mesajı değil, kendi
  // penceresini hak ediyor: kullanıcıya neden oynayamadığını, ne zaman
  // oynayabileceğini ve beklemek istemiyorsa ne olduğunu birlikte anlatır.
  if (apiResponse.errorCode != _noLivesErrorCode) {
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

  final scoreProvider = context.read<ScoreWithLivesProvider>();
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
