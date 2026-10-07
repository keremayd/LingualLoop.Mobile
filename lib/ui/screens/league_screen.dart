import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/ui/flows/league_promotion_flow.dart';
import 'package:lingualloop/ui/screens/league_promotion_screen.dart';
import 'package:provider/provider.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen>
    with WidgetsBindingObserver, RouteAware {
  static const _backgroundColor = Color(0xFF041227);
  // Profil ekranındaki kart dili: zemin renginde yüz, 0xFF0B2143 kontur
  // (yanlarda ince, üst köşelerde kaybolan) ve altta kalın taban dudağı.
  static const _cardFaceColor = Color(0xFF041227);
  static const _cardBorderColor = Color(0xFF0B2143);
  static const _rowMeColor = Color(0xFF163258);
  static const _textColor = Colors.white;
  static const _mutedTextColor = Color(0xFF8FA0B5);
  static const _firstRankColor = Color(0xFFFFB020);
  static const _accentColor = Color(0xFF1CB1F5);

  static const _leagueNames = <String, String>{
    'merkur': 'Merkür',
    'aytasi': 'Aytaşı',
    'yildiz': 'Yıldız',
    'kuyruklu': 'Kuyruklu',
    'mars': 'Mars',
    'uranus': 'Uranüs',
    'saturn': 'Satürn',
    'nebula': 'Nebula',
    'kosmoz': 'Kosmoz',
    'supernova': 'Supernova',
    'pulsar': 'Pulsar',
  };

  static const _leagueKeys = [
    'merkur',
    'aytasi',
    'yildiz',
    'kuyruklu',
    'mars',
    'uranus',
    'saturn',
    'nebula',
    'kosmoz',
    'supernova',
    'pulsar',
  ];

  Timer? _countdownTimer;
  bool _isRefreshing = false;
  bool _isShowingPromotion = false;
  ModalRoute<void>? _subscribedRoute;

  /// Rozet şeridi: sayfa başına bir lig; PageView mıknatıs gibi ortalar.
  PageController? _stripController;
  int _centeredIndex = 0;
  bool _didCenterOnActiveLeague = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLeague();
    });
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        routeObserver.unsubscribe(this);
      }
      routeObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _stripController?.dispose();
    super.dispose();
  }

  /// Şerit ilk veri geldiğinde kullanıcının kendi ligine yerleşir.
  void _ensureStripController(int activeIndex) {
    if (_stripController != null) {
      if (!_didCenterOnActiveLeague && _stripController!.hasClients) {
        _didCenterOnActiveLeague = true;
        _centeredIndex = activeIndex;
        _stripController!.jumpToPage(activeIndex);
      }
      return;
    }
    _centeredIndex = activeIndex;
    _stripController = PageController(
      initialPage: activeIndex,
      viewportFraction: _LeagueBadgeCarousel.viewportFraction,
    );
  }

  /// Üstteki route kapandı (örn. oyun ekranından dönüldü): skor değişmiş
  /// olabilir, lig verisini tazele.
  @override
  void didPopNext() {
    _refreshLeague();
  }

  /// Uygulama arka plandan döndü: sezon devrilmiş veya lig değişmiş
  /// olabilir, lig verisini tazele.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLeague();
    }
  }

  Future<void> _refreshLeague() async {
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Provider.of<UserService>(context, listen: false)
          .scoreWithLivesById(context);
    } catch (_) {
      // Ağ hatasında eldeki son veriyle devam et; kullanıcı pull-to-refresh
      // ile tekrar deneyebilir.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _schedulePendingPromotion();
      }
    }
  }

  void _schedulePendingPromotion() {
    if (_isShowingPromotion) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isShowingPromotion) return;
      final promotion = context
          .read<ScoreWithLivesProvider>()
          .scoreWithLives
          ?.league
          ?.pendingPromotion;
      if (promotion == null) return;

      _isShowingPromotion = true;
      try {
        await showPendingLeaguePromotion(context);
      } finally {
        _isShowingPromotion = false;
      }
    });
  }

  Future<void> _previewLeaguePromotion() async {
    final activeRank =
        context.read<ScoreWithLivesProvider>().scoreWithLives?.league?.rank ??
            8;
    final fromIndex = activeRank >= _leagueKeys.length
        ? _leagueKeys.length - 2
        : (activeRank - 1).clamp(0, _leagueKeys.length - 2);
    final toIndex = fromIndex + 1;
    final fromKey = _leagueKeys[fromIndex];
    final toKey = _leagueKeys[toIndex];

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LeaguePromotionScreen(
          promotion: LeaguePromotionResponse(
            fromRank: fromIndex + 1,
            fromLeagueKey: fromKey,
            fromLeagueName: _leagueNames[fromKey]!,
            toRank: toIndex + 1,
            toLeagueKey: toKey,
            toLeagueName: _leagueNames[toKey]!,
          ),
          // Tasarım simülasyonu gerçek terfi kaydını kapatmaz.
          onContinue: () async => true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: kDebugMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _previewLeaguePromotion,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF087EBA),
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'TERFİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.family,
                      fontSize: 15,
                      fontWeight: AppTypography.action,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Consumer<ScoreWithLivesProvider>(
          builder: (context, provider, child) {
            final league = provider.scoreWithLives?.league;

            return RefreshIndicator(
              color: _accentColor,
              backgroundColor: _cardBorderColor,
              onRefresh: _refreshLeague,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / 750;
                  final activeIndex = ((league?.rank ?? 1) - 1)
                      .clamp(0, _leagueKeys.length - 1)
                      .toInt();
                  _ensureStripController(activeIndex);

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      14 * scale,
                      40 * scale,
                      14 * scale,
                      60 * scale,
                    ),
                    children: [
                      _LeagueHeaderPanel(
                        scale: scale,
                        league: league,
                        leagueKeys: _leagueKeys,
                        controller: _stripController!,
                        displayedName:
                            _leagueNames[_leagueKeys[_centeredIndex]] ?? '',
                        onCenteredChanged: (index) {
                          if (index != _centeredIndex && mounted) {
                            setState(() => _centeredIndex = index);
                          }
                        },
                      ),
                      SizedBox(height: 34 * scale),
                      ..._buildLeaderboard(league, scale),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildLeaderboard(LeagueProgressResponse? league, double scale) {
    final entries = league?.leaderboard ?? const <LeagueLeaderboardEntry>[];

    return [
      for (final entry in entries)
        Padding(
          padding: EdgeInsets.fromLTRB(
            26 * scale,
            0,
            26 * scale,
            24 * scale,
          ),
          child: _LeaderboardRow(scale: scale, entry: entry),
        ),
    ];
  }
}

/// Kaydırılabilir rozet şeridi. Ortadaki rozet büyür, kenara giderken
/// küçülür ve parmağı bıraktığında PageView mıknatıs gibi en yakın rozeti
/// tam ortaya oturtur.
class _LeagueBadgeCarousel extends StatelessWidget {
  const _LeagueBadgeCarousel({
    required this.scale,
    required this.leagueKeys,
    required this.activeRank,
    required this.controller,
    required this.onCenteredChanged,
  });

  final double scale;
  final List<String> leagueKeys;
  final int activeRank;
  final PageController controller;
  final ValueChanged<int> onCenteredChanged;

  static const _centerSize = 168.0;
  static const _edgeSize = 124.0;

  /// Rozetler arasında her yerde aynı görünen boşluk.
  static const _gap = 9.0;

  /// Panelin iç genişliği: 750 tasarım birimi eksi liste ve panel dolguları.
  static const _panelInnerWidth = 674.0;

  /// PageView bölmesi iki küçük rozetin adımına eşitlenir; merkezin fazladan
  /// yer ihtiyacı [_centerExtra] ile ayrıca telafi edilir.
  static const viewportFraction = (_edgeSize + _gap) / _panelInnerWidth;

  /// Merkez rozet komşusundan bu kadar daha uzağa itilir; böylece
  /// merkez-komşu boşluğu da tam [_gap] olur.
  static const _centerExtra = (_centerSize - _edgeSize) / 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _centerSize * scale,
      child: PageView.builder(
        controller: controller,
        itemCount: leagueKeys.length,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        onPageChanged: onCenteredChanged,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              // Merkeze olan işaretli uzaklık: 0 = tam ortada,
              // +1 = bir sağdaki, -1 = bir soldaki.
              final page =
                  controller.hasClients && controller.position.haveDimensions
                      ? (controller.page ?? controller.initialPage.toDouble())
                      : controller.initialPage.toDouble();
              final delta = index - page;
              final distance = delta.abs().clamp(0.0, 1.0);
              final t = Curves.easeOut.transform(1 - distance);
              final size = _edgeSize + (_centerSize - _edgeSize) * t;
              final opacity = 0.72 + 0.28 * t;
              // Merkezin büyümesiyle açılan payı komşulara aktar: boşluk
              // hem merkezin iki yanında hem küçükler arasında eşit kalır.
              final shift = _centerExtra * delta.clamp(-1.0, 1.0) * scale;

              // OverflowBox: rozet bölmesinden genişse bile kare ölçüsünü
              // korur. Aksi halde kutuya sığdırılıp dikeyde geriliyor.
              return Transform.translate(
                offset: Offset(shift, 0),
                child: Center(
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Opacity(
                      opacity: opacity,
                      child: LeagueBadgeMark(
                        leagueKey: leagueKeys[index],
                        size: size * scale,
                        locked: (index + 1) > activeRank,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LeagueHeaderPanel extends StatelessWidget {
  const _LeagueHeaderPanel({
    required this.scale,
    required this.league,
    required this.leagueKeys,
    required this.controller,
    required this.displayedName,
    required this.onCenteredChanged,
  });

  final double scale;
  final LeagueProgressResponse? league;
  final List<String> leagueKeys;
  final PageController controller;

  /// Şeritte ortalanan ligin adı; kullanıcı gezindikçe başlık onu izler.
  final String displayedName;
  final ValueChanged<int> onCenteredChanged;

  String _countdownText() {
    final endsAt = league?.seasonEndsAtUtc;
    if (endsAt == null) {
      return 'Sezon bilgisi yükleniyor';
    }

    final remaining = endsAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      return 'Sezon yenileniyor';
    }

    if (remaining.inDays > 0) {
      final hours = remaining.inHours - remaining.inDays * 24;
      return '${remaining.inDays} gün $hours saat sonra sezon yenilenecek';
    }
    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes - remaining.inHours * 60;
      return '${remaining.inHours} saat $minutes dk sonra sezon yenilenecek';
    }
    return '${remaining.inMinutes} dk sonra sezon yenilenecek';
  }

  @override
  Widget build(BuildContext context) {
    final activeRank = league?.rank ?? 1;
    final radius = AppShapeStyle.cardRadius(46 * scale);

    return Container(
      decoration: BoxDecoration(
        color: _LeagueScreenState._cardBorderColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(7 * scale)),
      child: Container(
        decoration: BoxDecoration(
          color: _LeagueScreenState._cardFaceColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoTopBorderPainter(
                    color: _LeagueScreenState._cardBorderColor,
                    strokeWidth: AppShapeStyle.outline(2 * scale),
                    radius: radius,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                110 * scale,
                24 * scale,
                22 * scale,
              ),
              child: Column(
                children: [
                  _LeagueBadgeCarousel(
                    scale: scale,
                    leagueKeys: leagueKeys,
                    activeRank: activeRank,
                    controller: controller,
                    onCenteredChanged: onCenteredChanged,
                  ),
                  SizedBox(height: 34 * scale),
                  Text(
                    '$displayedName Ligi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _LeagueScreenState._textColor,
                      fontSize: 48 * scale,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 48 * scale),
                  Text(
                    _countdownText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _LeagueScreenState._mutedTextColor,
                      fontSize: 24 * scale,
                      fontWeight: AppTypography.caption,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.scale,
    required this.entry,
  });

  final double scale;
  final LeagueLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final faceHeight = 131 * scale - AppShapeStyle.cardDepth(7 * scale);
    final depth = AppShapeStyle.cardDepth(7 * scale);
    final cornerRadius = AppShapeStyle.cardRadius(26 * scale);
    final radius = BorderRadius.circular(cornerRadius);
    final rankColor = entry.rank == 1
        ? _LeagueScreenState._firstRankColor
        : _LeagueScreenState._textColor;

    return SizedBox(
      height: faceHeight + depth,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: depth,
            height: faceHeight,
            child: Container(
              decoration: BoxDecoration(
                color: _LeagueScreenState._cardBorderColor,
                borderRadius: radius,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: faceHeight,
            child: Container(
              padding: EdgeInsets.only(left: 6 * scale, right: 36 * scale),
              decoration: BoxDecoration(
                color: isMe
                    ? _LeagueScreenState._rowMeColor
                    : _LeagueScreenState._cardFaceColor,
                borderRadius: radius,
              ),
              foregroundDecoration: _NoTopBorderDecoration(
                color: _LeagueScreenState._cardBorderColor,
                strokeWidth: AppShapeStyle.outline(2 * scale),
                radius: cornerRadius,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52 * scale,
                    child: Text(
                      '${entry.rank}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 44 * scale,
                        fontWeight: AppTypography.number,
                        fontFamily: AppTypography.family,
                      ),
                    ),
                  ),
                  SizedBox(width: 22 * scale),
                  _RowAvatar(scale: scale, entry: entry),
                  SizedBox(width: 32 * scale),
                  Expanded(
                    child: Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _LeagueScreenState._textColor,
                        fontSize: 39 * scale,
                        fontWeight: AppTypography.label,
                        fontFamily: AppTypography.family,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Text(
                    '${entry.points} Puan',
                    style: TextStyle(
                      color: _LeagueScreenState._mutedTextColor,
                      fontSize: 30 * scale,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil kartlarındaki border dili (ProfileCard/_NoTopBorderPainter ile
/// aynı): üst kenarı olmayan, sol/sağ üst köşelerde gradyanla incelerek
/// biten kontur.
class _NoTopBorderPainter extends CustomPainter {
  const _NoTopBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final usableRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(inset, usableRadius)
      ..lineTo(inset, size.height - usableRadius)
      ..quadraticBezierTo(
        inset,
        size.height - inset,
        usableRadius,
        size.height - inset,
      )
      ..lineTo(size.width - usableRadius, size.height - inset)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - inset,
        size.height - usableRadius,
      )
      ..lineTo(size.width - inset, usableRadius);

    canvas.drawPath(path, paint);

    final leftCorner = Path()
      ..moveTo(usableRadius, inset)
      ..quadraticBezierTo(inset, inset, inset, usableRadius);
    final rightCorner = Path()
      ..moveTo(size.width - usableRadius, inset)
      ..quadraticBezierTo(
        size.width - inset,
        inset,
        size.width - inset,
        usableRadius,
      );

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      leftCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(usableRadius, inset),
          Offset(inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
    canvas.drawPath(
      rightCorner,
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(size.width - usableRadius, inset),
          Offset(size.width - inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _NoTopBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

/// [_NoTopBorderPainter]'ı Container.foregroundDecoration olarak
/// kullanabilmek için ince sarmalayıcı.
class _NoTopBorderDecoration extends Decoration {
  const _NoTopBorderDecoration({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NoTopBorderBoxPainter(this);
}

class _NoTopBorderBoxPainter extends BoxPainter {
  _NoTopBorderBoxPainter(this.decoration);

  final _NoTopBorderDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _NoTopBorderPainter(
      color: decoration.color,
      strokeWidth: decoration.strokeWidth,
      radius: decoration.radius,
    ).paint(canvas, size);
    canvas.restore();
  }
}

class _RowAvatar extends StatelessWidget {
  const _RowAvatar({
    required this.scale,
    required this.entry,
  });

  final double scale;
  final LeagueLeaderboardEntry entry;

  String _initials(String name) {
    final parts =
        name.split(' ').where((part) => part.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final size = 84 * scale;
    final radius = 20 * scale;

    // Kendi satırında fotoğraf, ana ekrandaki gibi provider üzerinden gelir.
    if (entry.isCurrentUser) {
      return ProfilePhotoWidget(
        width: size,
        height: size,
        borderRadius: radius,
        editable: false,
      );
    }

    final photoUrl = entry.profilePhotoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAF1),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(
              _initials(entry.displayName),
              style: TextStyle(
                color: const Color(0xFF35424E),
                fontSize: 28 * scale,
                fontWeight: AppTypography.label,
                fontFamily: AppTypography.family,
              ),
            )
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                _initials(entry.displayName),
                style: TextStyle(
                  color: const Color(0xFF35424E),
                  fontSize: 28 * scale,
                  fontWeight: AppTypography.label,
                  fontFamily: AppTypography.family,
                ),
              ),
            ),
    );
  }
}
