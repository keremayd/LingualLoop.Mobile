import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/countdown_pill.dart';
import 'package:lingualloop/ui/widgets/Popups/league_info_popup.dart';
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

  // Sıra ve adlar lig rozetinin ortak tablosunda (oyun özeti de kullanıyor).
  static const _leagueNames = LeagueVisuals.names;
  static const _leagueKeys = LeagueVisuals.order;

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
                  final nextLeagueKey =
                      league != null && league.rank < _leagueKeys.length
                          ? _leagueKeys[league.rank]
                          : null;

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
                        nextLeagueKey: nextLeagueKey,
                        nextLeagueName: nextLeagueKey == null
                            ? null
                            : _leagueNames[nextLeagueKey],
                        onInfoPressed: league == null
                            ? null
                            : () => showLeagueInfoPopup(
                                  context,
                                  league: league,
                                  nextLeagueName: league.rank <
                                          _leagueKeys.length
                                      ? _leagueNames[_leagueKeys[league.rank]]
                                      : null,
                                ),
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
      // Sıralama yalnız **aynı lig bandındaki** kullanıcıları gösteriyor;
      // kullanıcı az olduğu sürece çoğu zaman tek kişi kalınıyor ve ekranın
      // yarısı boş duruyordu. Tek olmak bir eksiklik değil: oraya ilk ulaşan
      // sensin. İkinci kişi geldiği an sahne listeye yerini bırakır.
      if (league != null && entries.length <= 1)
        _LeagueSoloScene(
          scale: scale,
          leagueName: _leagueNames[league.leagueKey] ?? league.leagueName,
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
    required this.nextLeagueKey,
    required this.nextLeagueName,
    required this.onInfoPressed,
    required this.onCenteredChanged,
  });

  final double scale;
  final LeagueProgressResponse? league;
  final List<String> leagueKeys;
  final PageController controller;

  /// Şeritte ortalanan ligin adı; kullanıcı gezindikçe başlık onu izler.
  final String displayedName;

  /// Kullanıcının **kendi** bir üst ligi; en üst ligde `null`. Başlık şeritte
  /// gezilen ligi izlerken ilerleme her zaman kullanıcının kendi hedefidir —
  /// bu yüzden metin hedef ligi adıyla söylüyor.
  final String? nextLeagueKey;
  final String? nextLeagueName;
  final VoidCallback? onInfoPressed;
  final ValueChanged<int> onCenteredChanged;

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
              // Üst pay 110'du ve boş duruyordu; o alan artık durum satırı.
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                22 * scale,
                24 * scale,
                22 * scale,
              ),
              child: Column(
                children: [
                  // Durum satırı: solda sezonun kalan süresi, sağda bilgi.
                  // Duolingo'nun 2026 sekme yenilemesindeki kalıp — süre ayrı
                  // bir satır değil, başlığın köşesinde küçük bir sayaç.
                  Row(
                    children: [
                      Expanded(
                        child: league == null
                            ? const SizedBox.shrink()
                            : _SeasonCountdown(scale: scale, league: league!),
                      ),
                      AppIconControlButton(
                        scale: scale,
                        label: 'Lig ve sezon bilgisi',
                        enabled: onInfoPressed != null,
                        onPressed: onInfoPressed ?? () {},
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: _LeagueScreenState._textColor,
                          size: 39 * scale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * scale),
                  _LeagueBadgeCarousel(
                    scale: scale,
                    leagueKeys: leagueKeys,
                    activeRank: activeRank,
                    controller: controller,
                    onCenteredChanged: onCenteredChanged,
                  ),
                  SizedBox(height: 34 * scale),
                  // Bilgi düğmesi durum satırına çıktı: başlık artık gerçekten
                  // ortalı (eskiden düğmeyi dengelemek için solda görünmez bir
                  // boşluk vardı).
                  Text(
                    '$displayedName Ligi',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _LeagueScreenState._textColor,
                      fontSize: 48 * scale,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1,
                    ),
                  ),
                  if (league != null) ...[
                    SizedBox(height: 26 * scale),
                    _LeagueProgress(
                      scale: scale,
                      league: league!,
                      nextLeagueKey: nextLeagueKey,
                      nextLeagueName: nextLeagueName,
                    ),
                    SizedBox(height: 26 * scale),
                  ] else
                    SizedBox(height: 48 * scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sıradaki lige ilerleme.
///
/// **Neden başlık kartının içinde:** listenin altına konsaydı kalabalık bir
/// ligde kaydırmadan görünmezdi. Başlıkta, sıralama ne kadar uzun olursa olsun
/// ekranın üstünde kalıyor.
///
/// Rozet şeridi ve başlık ortalı olduğu için blok da ortalı (tek hiza ekseni).
/// Sezon süresi burada değil, kartın durum satırında: puan ile süre aynı
/// blokta yarıştığında hangisinin asıl mesaj olduğu okunmuyordu. Çubuğun ucundaki
/// kilitli rozet hedefi gösterir — Görevler'deki "ödül barın ucunda"
/// kalıbının aynısı.
class _LeagueProgress extends StatelessWidget {
  const _LeagueProgress({
    required this.scale,
    required this.league,
    required this.nextLeagueKey,
    required this.nextLeagueName,
  });

  final double scale;
  final LeagueProgressResponse league;
  final String? nextLeagueKey;
  final String? nextLeagueName;

  /// Lig bilgi penceresindeki puan çubuğuyla aynı accent mavi: ekran ve
  /// pencere aynı ölçüyü aynı renkle göstersin (kullanıcı kararı, 3 Kas 2026).
  /// Bir tur profildeki lig hedefinin altını kullanıldı; altın bu uygulamada
  /// bilet semantiği (§5).
  static const _fill = _LeagueScreenState._accentColor;
  static const _track = _LeagueScreenState._rowMeColor;

  @override
  Widget build(BuildContext context) {
    final pointsLeft = league.pointsToNextLeague;
    final isTopLeague = pointsLeft == null || nextLeagueKey == null;
    const muted = _LeagueScreenState._mutedTextColor;
    final badgeSize = 64 * scale;
    final barHeight = 20 * scale;

    final message = TextStyle(
      color: muted,
      fontFamily: AppTypography.family,
      fontSize: 26 * scale,
      fontWeight: AppTypography.body,
      height: 1.2,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32 * scale),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: message,
              children: isTopLeague
                  ? const [TextSpan(text: 'En üst ligdesin')]
                  : [
                      TextSpan(text: '$nextLeagueName Ligi\'ne '),
                      TextSpan(
                        text: '$pointsLeft puan',
                        style: message.copyWith(
                          color: _fill,
                          fontWeight: AppTypography.number,
                        ),
                      ),
                      const TextSpan(text: ' kaldı'),
                    ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          if (!isTopLeague) ...[
            SizedBox(height: 14 * scale),
            SizedBox(
              height: badgeSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Çubuk rozetin ortasına kadar uzanır, ucu rozetin altına
                  // girer: dolgu "rozete doğru" akar.
                  Padding(
                    padding: EdgeInsets.only(right: badgeSize / 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      child: SizedBox(
                        height: barHeight,
                        child: LinearProgressIndicator(
                          value: league.progressRatio.clamp(0.0, 1.0),
                          backgroundColor: _track,
                          valueColor: const AlwaysStoppedAnimation(_fill),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: LeagueBadgeMark(
                      leagueKey: nextLeagueKey!,
                      size: badgeSize,
                      locked: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sezonun kalan süresi — Görevler başlığıyla aynı [CountdownPill].
class _SeasonCountdown extends StatelessWidget {
  const _SeasonCountdown({required this.scale, required this.league});

  final double scale;
  final LeagueProgressResponse league;

  @override
  Widget build(BuildContext context) {
    final remaining = league.seasonEndsAtUtc.difference(DateTime.now().toUtc());

    final String value;
    if (remaining <= Duration.zero) {
      value = 'Yenileniyor';
    } else if (remaining.inDays > 0) {
      value = '${remaining.inDays} gün';
    } else if (remaining.inHours > 0) {
      value = '${remaining.inHours} sa';
    } else {
      value = '${remaining.inMinutes} dk';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: CountdownPill(
        scale: scale,
        value: value,
        urgent: remaining > Duration.zero && remaining.inHours < 2,
        semanticLabel: 'Sezonun bitmesine $value',
      ),
    );
  }
}

/// Sıralamada tek kişi kalındığında gösterilen sahne.
///
/// Mesaj "kimse yok" değil, **"ilk sen ulaştın"**: yalnızlık başarının
/// parçası. Maskot lige bayrak dikiyor; bayraktaki şimşek sahneyi bir lig
/// olarak okutuyor.
///
/// Görselin zemini sayfa zemini (`041227`) ile birebir aynı tona çekildi;
/// çizim modeli daha mavi bir lacivert (`00163D`) üretmişti ve sayfada
/// çerçevesi belli oluyordu.
class _LeagueSoloScene extends StatelessWidget {
  const _LeagueSoloScene({required this.scale, required this.leagueName});

  final double scale;
  final String leagueName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(40 * scale, 6 * scale, 40 * scale, 0),
      child: Column(
        children: [
          Image.asset(
            'assets/scenes/lig_ilk_ulasan.png',
            // 430pt cihazda başlık, tek satır ve iki satırlık metin alt
            // menünün üstünde, kaydırmadan sığsın (560'ta alt satır menünün
            // altına kayıyordu).
            width: 470 * scale,
            semanticLabel: 'Lig gezegenine bayrak diken maskot',
          ),
          SizedBox(height: 6 * scale),
          Text(
            '$leagueName Ligi\'ne ilk sen ulaştın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LeagueScreenState._textColor,
              fontFamily: AppTypography.displayFamily,
              fontSize: 38 * scale,
              fontWeight: AppTypography.heading,
              height: 1.1,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            'Yeni rakipler yolda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LeagueScreenState._mutedTextColor,
              fontFamily: AppTypography.family,
              fontSize: 26 * scale,
              fontWeight: AppTypography.body,
              height: 1.2,
            ),
          ),
        ],
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
