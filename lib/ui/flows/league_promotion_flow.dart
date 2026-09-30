import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/league_promotion_screen.dart';
import 'package:provider/provider.dart';

/// Sunucunun henüz gösterilmedi olarak tuttuğu lig terfisini açar.
///
/// Kullanıcı ekranı gördükten sonra sunucu kaydı kapatılır; uygulama tam bu
/// anda kapanırsa terfi bir sonraki Lig sekmesi girişinde yeniden yakalanır.
Future<bool> showPendingLeaguePromotion(BuildContext context) async {
  final promotion = context
      .read<ScoreWithLivesProvider>()
      .scoreWithLives
      ?.league
      ?.pendingPromotion;
  if (promotion == null) return false;

  final userService = context.read<UserService>();
  final shown = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LeaguePromotionScreen(
            promotion: promotion,
            onContinue: () async {
              final response = await userService.acknowledgeLeaguePromotion();
              if (response.errorCode != null) return false;
              if (!context.mounted) return true;
              await userService.scoreWithLivesById(context);
              return true;
            },
          ),
        ),
      ) ??
      false;

  return shown;
}
