import 'package:flutter/widgets.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';
import 'package:stelinda/ui/widgets/home_top_bar.dart';
import 'package:stelinda/ui/widgets/practice_station_marks.dart';

/// Patika önizlemelerinin ortak üst şeridi ve yan durakları.
Widget previewPathHeader(
  double scale, {
  int streak = 4,
  bool playedToday = true,
  int tickets = 12,
}) =>
    HomeTopBar(
      scale: scale,
      streakDays: streak,
      playedToday: playedToday,
      tickets: tickets,
      maxTickets: 15,
    );

KartyPathStation previewArticleStation({
  required String detail,
  VoidCallback? onTap,
}) =>
    KartyPathStation(
      title: 'Artikel',
      spokenName: 'Artikel Pusulası',
      icon: (tile) => ArticleDragMark(size: tile * 0.8),
      detail: detail,
      onTap: onTap,
    );

KartyPathStation previewReviewStation({
  required String detail,
  VoidCallback? onTap,
}) =>
    KartyPathStation(
      title: 'Rövanş',
      spokenName: 'Karty Rövanş',
      icon: (tile) => RevengeCardMark(size: tile * 0.66),
      detail: detail,
      onTap: onTap,
    );

/// İki durak da açık: patikanın kendisine bakan önizlemeler için.
KartyPathStations previewStations() => KartyPathStations(
      article: previewArticleStation(detail: '6 kart', onTap: () {}),
      review: previewReviewStation(detail: '2 kart', onTap: () {}),
    );
