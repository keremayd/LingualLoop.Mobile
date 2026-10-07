import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';
import 'package:lingualloop/ui/widgets/ticket_with_count.dart';
import 'package:provider/provider.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with WidgetsBindingObserver, RouteAware, TickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF041227);
  static const _cardFaceColor = Color(0xFF041227);
  static const _cardBorderColor = Color(0xFF0B2143);
  static const _iconTileColor = Color(0xFF0C2244);
  static const _trackColor = Color(0xFF0B2143);
  static const _progressColor = Color(0xFFFFC93A);

  /// Henüz kazanılmamış ödülün tonu. Palet dışı değil: §2.6'daki `yildiz`
  /// lig taşının koyu tonu, yani bilet altınının belgeli koyusu.
  static const _dimGoldColor = Color(0xFFB87E00);
  static const _onProgressColor = Color(0xFF4A3400);
  static const _textColor = Colors.white;
  static const _mutedTextColor = Color(0xFF8FA0B5);
  static const _countdownValueColor = Color(0xFFE9EEF5);
  static const _countdownUrgentColor = Color(0xFFFF6B3D);
  static const _accentColor = Color(0xFF1CB1F5);

  Timer? _countdownTimer;
  ModalRoute<void>? _subscribedRoute;

  /// Ödül kutlaması sahnenin ortasında, perdeyle oynar. Kartın
  /// "Tamamlananlar"a kayması perdenin arkasında olur; perde kalktığında
  /// pano çoktan yerleşmiş olur.
  late final AnimationController _celebrationController;

  /// Kutlamadan sonra biletlerin sayaca uçuşu.
  late final AnimationController _flyController;

  /// Uçuşun hedefi: başlıktaki bilet sayacı. Konumu ancak yerleşimden sonra
  /// bilindiği için anahtarla ölçülüyor.
  /// Hedef **sayacın ikonu**, hapın ortası değil: bilet bilete konmalı.
  final GlobalKey _ticketIconKey = GlobalKey();

  /// Kaynak, ödülü alınan kartın kendisi. Kart ödülden sonra "Tamamlananlar"
  /// bölümüne kayıyor, bu yüzden konum **talep anında** ölçülüp saklanıyor.
  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _cardKey(String questKey) =>
      _cardKeys.putIfAbsent(questKey, () => GlobalKey());

  /// Kartın **global** konumu (talep anında ölçülür). Uçuş katmanına
  /// verilmeden önce yerel uzaya çevrilir — bkz. [_startTicketFly].
  Offset? _flyFromGlobal;

  Offset? _flyFrom;
  Offset? _flyTo;
  int _flyingCount = 0;

  /// Havada olan bilet sayısı; sayaç bunları varana kadar göstermez.
  int _pendingTickets = 0;
  String? _celebratingQuestKey;

  /// Sunucunun gerçekten verdiği bilet; tavana takılmışsa nominal ödülden
  /// küçüktür ve kutlama bu sayıyı gösterir.
  int _celebratedTickets = 0;
  String _celebratedTitle = '';

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _celebratingQuestKey = null);
          // Perde kalkar kalkmaz ödül sayaca doğru yola çıkar: kullanıcı
          // kazandığı şeyin nereye gittiğini görür.
          _startTicketFly();
        }
      });

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Biletler vardı: sayaç artık gerçek bakiyeyi gösterebilir.
          setState(() {
            _flyingCount = 0;
            _pendingTickets = 0;
            // Bayat konum bırakılmaz: ölçülemeyen bir sonraki talepte
            // biletler eski kartın yerinden kalkardı.
            _flyFromGlobal = null;
          });
        }
      });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestsProvider>().load();
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
    _celebrationController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  /// Oyun ekranından dönüldü: görev ilerlemeleri değişmiş olabilir.
  @override
  void didPopNext() {
    context.read<QuestsProvider>().load(silent: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<QuestsProvider>().load(silent: true);
    }
  }

  /// Kutlama bitince ödülü sayaca uçurur.
  ///
  /// Kaynak: kutlamanın biletinin durduğu yer (ekranın ortası) — kullanıcının
  /// gözü zaten oradadır. Hedef: başlıktaki sayaç. İkisi arasında düz çizgi
  /// yerine yay çizilir; düz çizgi "taşınıyor" değil "kayıyor" gibi duruyor.
  void _startTicketFly() {
    final icon =
        _ticketIconKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = context.findRenderObject() as RenderBox?;
    if (icon == null || overlay == null || _celebratedTickets <= 0) return;

    // **Koordinat uzayı tuzağı.** `localToGlobal` ekranın tepesine göre ölçer,
    // ama uçuş katmanı bu ekranın Scaffold'u içinde duruyor ve o Scaffold
    // ekranın tepesinden başlamıyor: `NavbarWidget` sayfaları
    // `SafeArea(bottom: false, ...)` ile sarıyor, yani gövde durum çubuğunun
    // altından başlıyor. Global koordinat doğrudan kullanılırsa her şey durum
    // çubuğu yüksekliği kadar aşağı kayar ve biletler sayacın altına konar.
    // Bu yüzden iki uç da katmanın **yerel** uzayına çevriliyor.
    final target = overlay.globalToLocal(
      icon.localToGlobal(icon.size.center(Offset.zero)),
    );
    // Kart ölçülemediyse (liste kaydırılmışsa) ekranın ortasına düşülür.
    final source = _flyFromGlobal == null
        ? overlay.size.center(Offset.zero)
        : overlay.globalToLocal(_flyFromGlobal!);

    setState(() {
      _flyFrom = source;
      _flyTo = target;
      // Ödül 10 bilet bile olsa 10 sprite uçurmak kalabalık yapıyor; sayı
      // sınırlanıyor, kullanıcı "birkaç bilet uçtu" olarak okuyor.
      _flyingCount = _celebratedTickets.clamp(1, 5);
      _pendingTickets = _celebratedTickets;
    });
    _flyController.forward(from: 0);
  }

  Future<void> _claim(String questKey) async {
    // Kart birazdan listede yer değiştirecek; kaynak konumu şimdi ölçülür.
    final cardBox =
        _cardKey(questKey).currentContext?.findRenderObject() as RenderBox?;
    final capturedFrom =
        cardBox?.localToGlobal(cardBox.size.center(Offset.zero));

    final result = await context.read<QuestsProvider>().claim(questKey);
    if (result == null || !mounted) return;

    // Bakiye tavandayken ödül verilemiyor ama **talep de tükenmiyor**: görev
    // alınabilir kalıyor. Kutlama çalıştırmak yanlış olurdu — kullanıcı
    // "0 bilet" görüp ödülü kaybettiğini sanıyordu.
    if (result.blockedByCap) {
      AppNotifier.showMessage(
        'Biletlerin dolu. Biraz oyna, sonra ödülünü al — görev seni bekliyor.',
      );
      return;
    }

    // Kutlama yalnızca ödül gerçekten alındığında çalışır.
    final quest = context
        .read<QuestsProvider>()
        .data
        ?.quests
        .where((q) => q.questKey == questKey)
        .firstOrNull;

    setState(() {
      _celebratingQuestKey = questKey;
      _celebratedTickets = result.rewardTickets;
      _celebratedTitle = quest?.title ?? '';
      // Bakiye birazdan tazelenecek ama ödül henüz "varmadı". Sayaç, biletler
      // uçup gelene kadar eski değerde tutulur; yoksa perde kalkar kalkmaz
      // sayı artar, sonra uçuş başlayınca geri düşer.
      _pendingTickets = result.rewardTickets;
      _flyFromGlobal = capturedFrom;
    });
    _celebrationController.forward(from: 0);

    // Bilet sayacı ana ekranla senkron kalsın.
    try {
      await Provider.of<UserService>(context, listen: false)
          .scoreWithLivesById(context);
    } catch (_) {}
  }

  /// Kutlamayı sunucuya dokunmadan tetikler. Yalnızca debug derlemesinde
  /// görünen tasarım aracı; animasyonu tekrar tekrar izleyip ayarlamak için.
  /// Tasarım kesinleşince bu buton ve `_DemoCelebrationButton` silinecek.
  void _playCelebrationDemo() {
    // Demo, ödül uçuşunu da gerçekçi göstersin: kaynak olarak ekrandaki ilk
    // alınmamış görev kartı ölçülür. Yoksa biletler ekranın ortasından
    // kalkıyor ve gerçek akıştan farklı görünüyordu.
    final quests =
        context.read<QuestsProvider>().data?.quests ?? const <DailyQuest>[];
    final sample = quests.where((q) => !q.isClaimed).firstOrNull;
    final box = sample == null
        ? null
        : _cardKey(sample.questKey).currentContext?.findRenderObject()
            as RenderBox?;

    setState(() {
      _celebratingQuestKey = '__demo__';
      _celebratedTickets = 3;
      _celebratedTitle = sample?.title ?? '3 günlük seriye ulaş';
      _flyFromGlobal = box?.localToGlobal(box.size.center(Offset.zero));
      _pendingTickets = 3;
    });
    _celebrationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          SafeArea(child: _buildBody()),
          // Tasarım aracı: kutlamayı sunucuya dokunmadan tetikler.
          // Release derlemesine girmez.
          if (kDebugMode)
            Positioned(
              right: 18,
              bottom: 28,
              child: SafeArea(
                child: _DemoCelebrationButton(onPressed: _playCelebrationDemo),
              ),
            ),
          // Kutlama tüm sahneyi kaplar: SafeArea'nın dışında kalır ki perde
          // çentik ve alt bant dahil her yeri örtsün.
          if (_celebratingQuestKey != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      return QuestRewardCelebration(
                        progress: _celebrationController.value,
                        scale: constraints.maxWidth / 670,
                        rewardTickets: _celebratedTickets,
                        questTitle: _celebratedTitle,
                      );
                    },
                  );
                },
              ),
            ),
          // Uçan biletler kutlamanın da üstünde: perde kalktıktan sonra
          // sahnede kalan tek hareket bu olmalı.
          if (_flyingCount > 0 && _flyFrom != null && _flyTo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flyController,
                  builder: (context, child) {
                    return _FlyingTickets(
                      progress: _flyController.value,
                      from: _flyFrom!,
                      to: _flyTo!,
                      count: _flyingCount,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Builder(
      builder: (context) {
        return Consumer<QuestsProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              color: _accentColor,
              backgroundColor: _cardBorderColor,
              onRefresh: () => provider.load(silent: true),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // İçerik ölçeği: tasarım referansı 670 birim genişlik.
                  // Tüm iç ölçüler bu tek katsayıya bağlı olduğu için
                  // mockup oranları korunur, içerik ekranı daha iyi doldurur.
                  final scale = constraints.maxWidth / 670;

                  if (provider.status == QuestsStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }

                  if (provider.status == QuestsStatus.error) {
                    return _ErrorState(
                      scale: scale,
                      onRetry: () => provider.load(),
                    );
                  }

                  final data = provider.data;
                  final quests = data?.quests ?? const <DailyQuest>[];

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      34 * scale,
                      36 * scale,
                      34 * scale,
                      54 * scale,
                    ),
                    children: [
                      _QuestsHeaderCard(
                        iconKey: _ticketIconKey,
                        pendingTickets: _pendingTickets,
                        fly: _flyController,
                        flyingCount: _flyingCount,
                        scale: scale,
                        resetAtUtc: data?.resetAtUtc,
                        quests: quests,
                      ),
                      SizedBox(height: 34 * scale),
                      _buildQuestBoard(quests, scale, provider),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Görev kartlarını konumlarını hesaplayarak yerleştirir: ödülü alınanlar
  /// "Tamamlananlar" başlığının altına kayar. Kart yükseklikleri sabit
  /// olduğu için hedef konumlar hesaplanabiliyor ve geçiş animasyonlu olur.
  Widget _buildQuestBoard(
    List<DailyQuest> quests,
    double scale,
    QuestsProvider provider,
  ) {
    const animationDuration = Duration(milliseconds: 420);
    final activeHeight = _QuestCard.totalHeight(scale);
    final completedHeight = _CompletedQuestRow.totalHeight(scale);
    final activeGap = 22 * scale;
    final completedGap = 15 * scale;
    final sectionHeaderHeight = 73 * scale;
    final allDoneHeight = 96 * scale;

    final active = quests.where((q) => !q.isClaimed).toList();
    final claimed = quests.where((q) => q.isClaimed).toList();

    final tops = <String, double>{};
    var cursor = 0.0;

    if (active.isEmpty && quests.isNotEmpty) {
      cursor += allDoneHeight;
    }
    for (final quest in active) {
      tops[quest.questKey] = cursor;
      cursor += activeHeight + activeGap;
    }

    double? sectionHeaderTop;
    if (claimed.isNotEmpty) {
      sectionHeaderTop = cursor;
      cursor += sectionHeaderHeight;
      for (final quest in claimed) {
        tops[quest.questKey] = cursor;
        cursor += completedHeight + completedGap;
      }
    }

    return AnimatedSize(
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: cursor,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (active.isEmpty && quests.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: allDoneHeight,
                child: Center(
                  child: Text(
                    'Bugünün tüm görevlerini bitirdin.',
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 26 * scale,
                      fontWeight: AppTypography.body,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ),
              ),
            if (sectionHeaderTop != null)
              AnimatedPositioned(
                key: const ValueKey('completed-section-header'),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: sectionHeaderTop,
                height: sectionHeaderHeight,
                child: _CompletedSectionHeader(scale: scale),
              ),
            for (final quest in quests)
              AnimatedPositioned(
                key: ValueKey(quest.questKey),
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: tops[quest.questKey] ?? 0,
                height: quest.isClaimed ? completedHeight : activeHeight,
                child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: quest.isClaimed ? 0.72 : 1,
                  child: quest.isClaimed
                      ? _CompletedQuestRow(
                          scale: scale,
                          quest: quest,
                          icon: QuestIcon(
                            questKey: quest.questKey,
                            size: 32 * scale,
                          ),
                        )
                      : _QuestCard(
                          // Ödül uçuşunun kaynağı bu kart; konumu talep
                          // anında bu anahtarla ölçülüyor.
                          key: _cardKey(quest.questKey),
                          scale: scale,
                          quest: quest,
                          isClaiming: provider.isClaiming(quest.questKey),
                          onClaim: () => _claim(quest.questKey),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSectionHeader extends StatelessWidget {
  const _CompletedSectionHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tamamlananlar',
          style: TextStyle(
            color: _QuestsScreenState._mutedTextColor,
            fontSize: 26 * scale,
            fontWeight: AppTypography.heading,
            fontFamily: AppTypography.displayFamily,
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Container(
            height: 2 * scale,
            color: _QuestsScreenState._cardBorderColor,
          ),
        ),
      ],
    );
  }
}

class _QuestsHeaderCard extends StatelessWidget {
  const _QuestsHeaderCard({
    required this.scale,
    required this.resetAtUtc,
    required this.quests,
    required this.iconKey,
    required this.pendingTickets,
    required this.fly,
    required this.flyingCount,
  });

  /// Uçan biletlerin hedefi. Konumu ölçülebilsin diye dışarıdan veriliyor.
  final GlobalKey iconKey;

  final Animation<double> fly;
  final int flyingCount;

  /// Kutlamadan sonra havada olan biletler. Sayaç, biletler **varana kadar**
  /// bu kadar eksik gösterir; yoksa ödül daha uçmadan bakiyeye eklenmiş olur
  /// ve animasyonun anlamı kalmaz.
  final int pendingTickets;

  final double scale;
  final DateTime? resetAtUtc;
  final List<DailyQuest> quests;

  /// "2/5 görev · 15 bilet kazanıldı, 35 bilet duruyor" gibi günlük özet.
  String _summaryText() {
    if (quests.isEmpty) return '';

    final done = quests.where((q) => q.isClaimed).length;
    final earned = quests
        .where((q) => q.isClaimed)
        .fold<int>(0, (sum, q) => sum + q.rewardTickets);
    final remaining = quests
        .where((q) => !q.isClaimed)
        .fold<int>(0, (sum, q) => sum + q.rewardTickets);

    final head = '$done/${quests.length} görev';
    if (earned == 0) return '$head · $remaining bilet seni bekliyor';
    if (remaining == 0) return '$head · $earned bilet kazandın';
    return '$head · $earned bilet kazandın, $remaining bilet duruyor';
  }

  /// Süre kritikleşince (son 2 saat) geri sayım sıcak tona geçer; renk
  /// sürekli yanan bir vurgu değil, gerçek bir aciliyet sinyali olur.
  bool _isUrgent() {
    final endsAt = resetAtUtc;
    if (endsAt == null) return false;

    final remaining = endsAt.difference(DateTime.now().toUtc());
    return !remaining.isNegative && remaining.inMinutes <= 120;
  }

  String _countdownText() {
    final endsAt = resetAtUtc;
    if (endsAt == null) return '';

    final remaining = endsAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Görevler yenileniyor';

    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes - remaining.inHours * 60;
      return '${remaining.inHours} sa $minutes dk';
    }
    return '${remaining.inMinutes} dk';
  }

  @override
  Widget build(BuildContext context) {
    return _QuestSurface(
      scale: scale,
      radius: 34 * scale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          36 * scale,
          34 * scale,
          30 * scale,
          32 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günlük Görevler',
                        style: TextStyle(
                          color: _QuestsScreenState._textColor,
                          fontSize: 36 * scale,
                          fontWeight: AppTypography.heading,
                          fontFamily: AppTypography.displayFamily,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 18 * scale),
                      Row(
                        children: [
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            color: _isUrgent()
                                ? _QuestsScreenState._countdownUrgentColor
                                : _QuestsScreenState._mutedTextColor,
                            size: 27 * scale,
                          ),
                          SizedBox(width: 6 * scale),
                          Text(
                            _countdownText(),
                            style: TextStyle(
                              color: _isUrgent()
                                  ? _QuestsScreenState._countdownUrgentColor
                                  : _QuestsScreenState._countdownValueColor,
                              fontSize: 22 * scale,
                              fontWeight: AppTypography.number,
                              fontFamily: AppTypography.family,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Flexible(
                            child: Text(
                              'sonra yenilenir',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _QuestsScreenState._mutedTextColor,
                                fontSize: 22 * scale,
                                fontWeight: AppTypography.caption,
                                fontFamily: AppTypography.family,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14 * scale),
                // Bayrak yerine bilet sayacı: başlıkta dekoratif bir simge
                // yerine **durumu değişen** bir sayı duruyor. Uçan biletlerin
                // hedefi de burası.
                _TicketCounter(
                  scale: scale,
                  pendingTickets: pendingTickets,
                  iconKey: iconKey,
                  fly: fly,
                  flyingCount: flyingCount,
                ),
              ],
            ),
            if (quests.isNotEmpty) ...[
              SizedBox(height: 25 * scale),
              _DailyGoalBar(scale: scale, quests: quests),
              SizedBox(height: 15 * scale),
              Text(
                _summaryText(),
                style: TextStyle(
                  color: _QuestsScreenState._mutedTextColor,
                  fontSize: 22 * scale,
                  fontWeight: AppTypography.caption,
                  fontFamily: AppTypography.family,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Günlük hedef çubuğu: her görev için bir bölme. Ödülü alınanlar dolu,
/// tamamlanıp henüz alınmayanlar yarı saydam gösterilir.
/// Uçuş zamanlaması. Hem uçan biletler hem sayaç aynı matematiği okur;
/// ayrı hesaplasalardı sayaç, bilet ona değmeden ya da değdikten sonra artardı.
class _FlyMath {
  const _FlyMath._();

  /// Sıradaki biletin kalkış gecikmesi (denetleyicinin oranı olarak).
  static const stagger = 0.10;

  /// Tek bir biletin uçuşunun kapladığı oran.
  static double span(int count) => 1 - (count - 1) * stagger;

  /// [i] numaralı biletin 0→1 ilerlemesi.
  static double t(int i, double progress, int count) {
    return ((progress - i * stagger) / span(count)).clamp(0.0, 1.0);
  }

  /// Sayaca varmış bilet adedi.
  static int landed(double progress, int count) {
    var n = 0;
    for (var i = 0; i < count; i++) {
      if (t(i, progress, count) >= 1) n++;
    }
    return n;
  }

  /// Varış darbesi: bir bilet değdiğinde sayaç kısa bir sıçrama yapar.
  /// Sayı sessizce artsaydı ödülün "geldiği" hissedilmezdi.
  static double pulse(double progress, int count) {
    var best = 0.0;
    for (var i = 0; i < count; i++) {
      final landAt = i * stagger + span(count);
      final since = progress - landAt;
      if (since < 0) continue;
      final decay = 1 - (since / 0.16);
      if (decay > best) best = decay;
    }
    return 1 + 0.22 * best.clamp(0.0, 1.0);
  }
}

/// Ödülden sayaca uçan biletler.
///
/// Hareketin üç işi var: **kalkış** (ödülden kopuş), **yol** (nereye gittiği)
/// ve **varış** (bakiyeye girişi). Üçü de okunmazsa animasyon "bir şeyler
/// kaydı" olarak kalıyor.
class _FlyingTickets extends StatelessWidget {
  const _FlyingTickets({
    required this.progress,
    required this.from,
    required this.to,
    required this.count,
  });

  final double progress;
  final Offset from;
  final Offset to;
  final int count;

  static const _size = 58.0;

  @override
  Widget build(BuildContext context) {
    final sprites = <Widget>[];

    for (var i = 0; i < count; i++) {
      final t = _FlyMath.t(i, progress, count);
      if (t <= 0 || t >= 1) continue;

      // Kalkış yavaş, yol hızlı, varış frenli. Tek bir easeInOut düz bir
      // kayma veriyordu; ödülün "fırlaması" bu eğriden geliyor.
      final eased = Curves.easeInOutCubic.transform(t);

      // Yay: kontrol noktası iki uç arasının üstünde. Biletler farklı
      // yüksekliklerden geçer ki demet tek çizgiye yapışmasın.
      final mid = Offset.lerp(from, to, 0.5)!;
      final spread = (i - (count - 1) / 2) * 34.0;
      final control =
          Offset(mid.dx + spread, mid.dy - 190 - (i.isEven ? 30 : 0));
      final pos = _quadratic(from, control, to, eased);

      // Kalkışta hafif büyüyüp sonra sayaca doğru küçülür: yaklaşırken
      // uzaklaşıyor değil, **içine giriyor** gibi okunsun.
      final pop =
          t < 0.18 ? 1 + 0.35 * (t / 0.18) : 1.35 - 1.05 * ((t - 0.18) / 0.82);
      final scale = pop.clamp(0.28, 1.35);

      // Yolda hafif dönme; sabit duran bir ikon çıkartma gibi görünüyordu.
      final spin = (i.isEven ? 1 : -1) * eased * 0.9;

      // Son anda söner ki sayacın üstünde bir kare takılı kalmasın.
      final opacity = t > 0.86 ? (1 - (t - 0.86) / 0.14) : 1.0;

      sprites.add(Positioned(
        left: pos.dx - _size * scale / 2,
        top: pos.dy - _size * scale / 2,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: spin,
            child: Image.asset(
              // Kutlamadaki büyük ödül de sayaç da yıldızlı bilet; uçan
              // parçalar farklı ikon olsaydı süreklilik kopardı.
              'assets/icons/ticket.png',
              width: _size * scale,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ));
    }

    return Stack(children: sprites);
  }

  Offset _quadratic(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
  }
}

/// Görevler başlığındaki toplam bilet sayacı.
///
/// Eskiden burada dekoratif bir bayrak duruyordu. Sayaç hem ödülün nereye
/// gittiğini gösteriyor hem de uçan biletlere bir hedef veriyor.
///
/// Sayı, uçuş animasyonuyla **senkron** artar: her bilet sayaca değdiği anda
/// bir artış ve kısa bir sıçrama olur. Sayı önceden artsaydı animasyonun
/// anlamı, sonra artsaydı da varışın karşılığı kalmazdı.
class _TicketCounter extends StatelessWidget {
  const _TicketCounter({
    required this.scale,
    required this.pendingTickets,
    required this.iconKey,
    required this.fly,
    required this.flyingCount,
  });

  final double scale;
  final int pendingTickets;

  /// Uçan biletlerin hedefi bu ikon — hapın ortası değil.
  final GlobalKey iconKey;

  final Animation<double> fly;
  final int flyingCount;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreWithLivesProvider>(
      builder: (context, provider, child) {
        final total = provider.scoreWithLives?.lives ?? 0;
        // Tavan kullanıcı bazında değişebiliyor (premium `max_lives`'ı
        // yükseltecek), o yüzden sabit 15 değil satırdan okunur.
        final maxLives = provider.scoreWithLives?.maxLives ?? 0;

        return AnimatedBuilder(
          animation: fly,
          builder: (context, child) {
            var shown = total - pendingTickets;
            var bump = 1.0;

            if (flyingCount > 0 && pendingTickets > 0) {
              final landed = _FlyMath.landed(fly.value, flyingCount);
              // Ödül 3 bilet ama 5 sprite uçuyor olabilir; varan sprite oranı
              // kadar bilet düşülür.
              shown += (pendingTickets * landed / flyingCount).round();
              bump = _FlyMath.pulse(fly.value, flyingCount);
            }

            // Bakiye = **yıldızlı bilet + sayı yanında** (§4.3: ticket.png
            // bakiyenin simgesi). Sayı biletin yüzüne yazılıyorken başlıktaki
            // bakiye ile satırlardaki ödül aynı nesne oluyordu; ekranda
            // 15 · 2 · 2 · 3 diziliyor ve hangisinin "sende olan", hangisinin
            // "kazanacağın" olduğunu yalnızca konum söylüyordu.
            return Transform.scale(
              scale: bump,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kalınlık bandı: aşağıdaki ödül biletleriyle aynı dil.
                  // Bu bilet bir süre ekrandaki **tek düz** bilet kaldı —
                  // ödüller derinlik, hâle ve hareket kazanırken başlıktaki
                  // gölgesiz PNG olarak durunca işlenmemiş görünüyordu.
                  SizedBox(
                    // Kesir eklenince sayaç genişledi ve geri sayım
                    // kırpılmaya başladı ("sonra yenile..."). Bilet ve sayı
                    // küçültülerek yer açıldı; kırpılan metin bilgi kaybıdır.
                    width: 100 * scale,
                    height: 100 * scale * 110 / 172 + 6 * scale,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 6 * scale,
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                _QuestsScreenState._dimGoldColor,
                                _QuestsScreenState._dimGoldColor,
                              ],
                            ).createShader(rect),
                            child: Image.asset(
                              'assets/icons/ticket.png',
                              width: 100 * scale,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Image.asset(
                            'assets/icons/ticket.png',
                            // Uçan biletlerin hedefi bu ikon — sayı değil.
                            key: iconKey,
                            width: 100 * scale,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  // Tavan **yazıyla** gösteriliyor: "13/15". Bir tur boyunca
                  // kesir yerine kap çizmeyi (çubuk, bölmeli kap) denedik,
                  // hepsi başka sebeplerden elendi — kullanıcı kararıyla
                  // kesire dönüldü, çünkü tavanın anlaşılması önceliklendi.
                  //
                  // Tavandayken **renk değişmiyor**: dolu olmak iyi bir
                  // durum; aciliyet tonu (§2.10) onu cezaya çevirirdi.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${shown.clamp(0, 9999)}',
                        style: TextStyle(
                          color: _QuestsScreenState._textColor,
                          fontFamily: AppTypography.family,
                          fontSize: 40 * scale,
                          fontWeight: AppTypography.number,
                          height: 1,
                        ),
                      ),
                      // Tavan henüz yüklenmediyse kesir hiç çizilmez; "13/0"
                      // göstermek bakiyeyi yalanlar.
                      if (maxLives > 0)
                        Text(
                          '/$maxLives',
                          style: TextStyle(
                            color: _QuestsScreenState._mutedTextColor,
                            fontFamily: AppTypography.family,
                            fontSize: 24 * scale,
                            fontWeight: AppTypography.caption,
                            height: 1,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyGoalBar extends StatelessWidget {
  const _DailyGoalBar({
    required this.scale,
    required this.quests,
  });

  final double scale;
  final List<DailyQuest> quests;

  @override
  Widget build(BuildContext context) {
    // Bölmeler görev sırasına göre değil, soldan sırayla dolar: önce ödülü
    // alınanlar, ardından tamamlanıp henüz alınmayanlar.
    final claimedCount = quests.where((q) => q.isClaimed).length;
    final readyCount =
        quests.where((q) => !q.isClaimed && q.isCompleted).length;

    return Row(
      children: [
        for (var i = 0; i < quests.length; i++) ...[
          if (i > 0) SizedBox(width: 9 * scale),
          Expanded(
            child: Container(
              height: 15 * scale,
              decoration: BoxDecoration(
                color: i < claimedCount
                    ? _QuestsScreenState._progressColor
                    : i < claimedCount + readyCount
                        ? _QuestsScreenState._progressColor
                            .withValues(alpha: 0.42)
                        : _QuestsScreenState._trackColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    super.key,
    required this.scale,
    required this.quest,
    required this.isClaiming,
    required this.onClaim,
  });

  final double scale;
  final DailyQuest quest;
  final bool isClaiming;
  final VoidCallback onClaim;

  /// 138'den 152'ye çıktı: ödül ayrı sütundan **metin sütununun içine**
  /// taşındı (barın ucuna), yani satırın dikey yükü arttı. İki satırlık
  /// başlıkta (örn. "2 rövanş kartını geri kazan") 138 taşıyordu:
  /// başlık 2×29 + boşluk 13 + ödül 72 = 143 > 138.
  static const _faceHeight = 152.0;
  static const _lipHeight = 7.0;

  /// Barın ucundaki ödülün kapladığı yükseklik. 430px cihazda ≈46pt eder —
  /// dokunma hedefi olarak Apple'ın 44pt alt sınırının üstünde kalmalı,
  /// bu yüzden küçültmek yerine kart yüksekliği büyütüldü.
  static const _endCapSize = 72.0;

  /// Kart yüzü + taban dudağı. Görev panosu konumları bu sabite dayanır.
  static double totalHeight(double scale) => (_faceHeight + _lipHeight) * scale;

  Widget questIcon({double? size}) {
    return QuestIcon(
      questKey: quest.questKey,
      size: size ?? 48 * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fraction = quest.target == 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);

    return _QuestSurface(
      scale: scale,
      radius: 28 * scale,
      child: Container(
        height: _faceHeight * scale,
        padding: EdgeInsets.symmetric(horizontal: 25 * scale),
        child: Row(
          children: [
            Container(
              width: 87 * scale,
              height: 87 * scale,
              decoration: BoxDecoration(
                color: _QuestsScreenState._iconTileColor,
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              alignment: Alignment.center,
              child: questIcon(),
            ),
            SizedBox(width: 25 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _QuestsScreenState._textColor,
                      fontSize: 25 * scale,
                      fontWeight: AppTypography.label,
                      fontFamily: AppTypography.family,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 13 * scale),
                  // Ödül, barın **varış noktası**. Ayrı bir sütunda dururken
                  // bar bir yere doğru dolmuyordu; goal-gradient etkisi ancak
                  // hedef görünürse çalışır (Duolingo'nun sandığı da barın
                  // ucundadır). Bar sağdan içeri çekilir, ödül ucuna biner.
                  SizedBox(
                    height: _endCapSize * scale,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 46 * scale),
                          child: _QuestProgressBar(
                            scale: scale,
                            fraction: fraction,
                            label: '${quest.progress}/${quest.target}',
                          ),
                        ),
                        Positioned(right: 0, child: _rewardEndCap()),
                      ],
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

  /// Barın ucundaki ödül — iki hâli var (§5 "sönükten parlağa"):
  /// bekleyen kısık ve küçük, hazır olan tam renk, kabarık, hâleli ve nabız
  /// atıyor. Yeşil kap kullanılmaz; yükseltmeyi boyut + doygunluk + kabartma
  /// + hâle birlikte taşır.
  Widget _rewardEndCap() {
    if (quest.isCompleted) {
      return _ClaimButton(
        // Testin dokunabilmesi için sabit anahtar: talep gönderme durumu
        // ancak dokunarak üretilebiliyor ve o durumun golden'ı olmadığı için
        // iki hata canlıya kadar gitmişti (bkz. quest_claim_pending_test).
        key: ValueKey('claim-${quest.questKey}'),
        scale: scale,
        rewardTickets: quest.rewardTickets,
        isClaiming: isClaiming,
        onPressed: onClaim,
      );
    }

    return TicketWithCount(
      scale: scale,
      count: quest.rewardTickets,
      ticketWidth: 62,
      badgeSize: 30,
      dim: true,
    );
  }
}

/// Ödülü alınmış görev: bar ve büyük ikon kalkar, satır yarı yüksekliğe iner.
/// Kart yüzeyi ve border dili aktif kartlarla aynı kalır.
class _CompletedQuestRow extends StatelessWidget {
  const _CompletedQuestRow({
    required this.scale,
    required this.quest,
    required this.icon,
  });

  final double scale;
  final DailyQuest quest;
  final Widget icon;

  static const _faceHeight = 91.0;
  static const _lipHeight = 7.0;

  static double totalHeight(double scale) => (_faceHeight + _lipHeight) * scale;

  @override
  Widget build(BuildContext context) {
    return _QuestSurface(
      scale: scale,
      radius: 22 * scale,
      child: Container(
        height: _faceHeight * scale,
        padding: EdgeInsets.symmetric(horizontal: 25 * scale),
        child: Row(
          children: [
            Container(
              width: 58 * scale,
              height: 58 * scale,
              decoration: BoxDecoration(
                color: _QuestsScreenState._iconTileColor,
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            SizedBox(width: 22 * scale),
            Expanded(
              child: Text(
                quest.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFC7D2E0),
                  fontSize: 24 * scale,
                  fontWeight: AppTypography.label,
                  fontFamily: AppTypography.family,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              '+${quest.rewardTickets}',
              style: TextStyle(
                color: _QuestsScreenState._mutedTextColor,
                fontSize: 20 * scale,
                fontWeight: AppTypography.number,
                fontFamily: AppTypography.family,
              ),
            ),
            SizedBox(width: 14 * scale),
            QuestCheckMark(size: 44 * scale),
          ],
        ),
      ),
    );
  }
}

class _QuestProgressBar extends StatelessWidget {
  const _QuestProgressBar({
    required this.scale,
    required this.fraction,
    required this.label,
  });

  final double scale;
  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    final height = 25 * scale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: _QuestsScreenState._trackColor),
            ),
            if (fraction > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _QuestsScreenState._progressColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ),
            // Etiket iki kez çizilir: dolgunun üstünde koyu, boş kısımda
            // beyaz. Böylece barın doluluğu ne olursa olsun okunur kalır.
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _QuestsScreenState._textColor,
                  fontSize: 18 * scale,
                  fontWeight: AppTypography.number,
                  fontFamily: AppTypography.family,
                ),
              ),
            ),
            if (fraction > 0)
              ClipRect(
                clipper: _FillClipper(fraction),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _QuestsScreenState._onProgressColor,
                      fontSize: 18 * scale,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Etiketin yalnızca barın dolu kısmına denk gelen bölümünü gösterir.
class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _FillClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _ClaimButton extends StatefulWidget {
  const _ClaimButton({
    super.key,
    required this.scale,
    required this.rewardTickets,
    required this.isClaiming,
    required this.onPressed,
  });

  final double scale;
  final int rewardTickets;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton>
    with SingleTickerProviderStateMixin {
  /// Kaydırılabilir liste içinde tap tanıyıcısı arenayı geç kazandığı için
  /// onTapDown ile onTapUp aynı karede gelebiliyor; çökme hissi kaybolmasın
  /// diye basılı görünüm en az bu süre kadar korunur.
  static const _minPressDuration = Duration(milliseconds: 120);

  /// Biletin genişliği ve kalınlık bandının derinliği (tasarım birimi).
  static const _ticketWidth = 76.0;
  static const _depth = 6.0;

  bool _isPressed = false;
  DateTime? _pressStartedAt;

  /// Zıplama: "buraya dokunulabilir" sinyalini yeşil bir kap yerine hareket
  /// taşıyor. Duolingo'da da hazır sandığın üstünde yazı yoktur; zıplar.
  ///
  /// Önce nabız (ölçek 1→1.035) denendi ve **görünmüyordu**. Zıplama hem daha
  /// güçlü hem uygulamanın oyuncak diline daha yakın.
  ///
  /// **Sürekli zıplamaz.** Döngünün yalnızca ilk ~%30'unda sıçrar, kalanında
  /// durur. Aralıksız zıplayan bir öğe birkaç saniyede gürültüye dönüşür;
  /// aradaki duruş sıçramayı yeniden fark edilir kılıyor.
  ///
  /// `repeat()` düz kullanılır (reverse değil) çünkü hareket **asimetrik**:
  /// çıkış `easeOut` (zirveye yavaşlayarak), iniş `easeIn` (yerçekimi gibi
  /// hızlanarak). §4.4'teki "döngü kapanmalı" kuralı sağlanıyor: dinlenme
  /// evresinde yükseklik de eziliş de tam sıfır, yani t=1 ile t=0 aynı kare.
  late final AnimationController _pulse;

  /// Döngünün zıplamaya ayrılan kısmı ve iniş sonrası eziliş penceresi.
  static const _hopSpan = 0.30;
  static const _squashStart = 0.30;
  static const _squashSpan = 0.09;

  /// Sıçrama yüksekliği (tasarım birimi).
  static const _hopHeight = 12.0;

  /// Hâlenin biletten her yöne taşma payı (tasarım birimi).
  static const _glowPad = 13.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (!widget.isClaiming) _pulse.repeat();
  }

  /// Zıplamanın o andaki yüksekliği (0–1) ve iniş ezilişi (0–1).
  ({double lift, double squash}) _hop(double v) {
    if (v < _hopSpan) {
      final p = v / _hopSpan;
      if (p < 0.42) {
        // Çıkış: hızlı başlar, zirveye yavaşlayarak varır.
        return (lift: Curves.easeOut.transform(p / 0.42), squash: 0);
      }
      // İniş: zirvede yavaş, yere doğru hızlanır.
      final f = (p - 0.42) / 0.58;
      return (lift: 1 - Curves.easeIn.transform(f), squash: 0);
    }
    if (v < _squashStart + _squashSpan) {
      // Yere değdikten hemen sonra kısa bir eziliş — sıçramaya ağırlık verir.
      return (
        lift: 0,
        squash: math.sin(math.pi * (v - _squashStart) / _squashSpan),
      );
    }
    return (lift: 0, squash: 0);
  }

  @override
  void didUpdateWidget(covariant _ClaimButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Talep gönderilirken nabız durur: dönen gösterge zaten "çalışıyor" diyor.
    if (widget.isClaiming && _pulse.isAnimating) {
      // `stop()` tek başına yetmez: controller **bulunduğu değerde donar**.
      // Bilet havadayken talep gönderilirse o değer havada kilitleniyor ve
      // basılı durum kalkınca yükseklik yeniden uygulanıyordu — bilet yere
      // inmeden asılı kalıyordu. Sıfırlamak onu yere oturtur.
      _pulse.stop();
      _pulse.value = 0;
    } else if (!widget.isClaiming && !_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleDown() {
    _pressStartedAt = DateTime.now();
    setState(() => _isPressed = true);
  }

  Future<void> _releasePress() async {
    final elapsed = _pressStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_pressStartedAt!);
    if (elapsed < _minPressDuration) {
      await Future<void>.delayed(_minPressDuration - elapsed);
    }
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final w = _ticketWidth * scale;
    final h = w * 110 / 172;
    final depth = _depth * scale;
    final badge = 32 * scale;

    return GestureDetector(
      onTapDown: (_) => _handleDown(),
      onTapCancel: _releasePress,
      onTapUp: (_) {
        if (!widget.isClaiming) widget.onPressed();
        _releasePress();
      },
      child: SizedBox(
        width: w + badge * 0.42,
        height: h + depth + badge * 0.34,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // Basılıyken zıplama durur: o an kullanıcının hareketi baskın.
            final hop =
                _isPressed ? (lift: 0.0, squash: 0.0) : _hop(_pulse.value);
            final lift = hop.lift * _hopHeight * scale;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Sıcak hâle — hazır olduğunu söyleyen ortam ışığı.
                //
                // **Biçimi biletin kendisinden gelir.** Önce yuvarlak bir
                // radyal gradyandı; bilet dikdörtgene yakın olduğu için hâle
                // ondan taşıyor ve arkada ayrı bir daire gibi okunuyordu.
                // Siluet elle çizilmez (§5): `ticket.png` büyütülüp altına
                // boyanır ve bulanıklaştırılır — premium biletteki maskeleme
                // yönteminin aynısı.
                //
                // Zıplamaya **eşlik eder**: bu bir gölge değil, biletin kendi
                // ışıması. Işık kaynağı hareket ediyorsa ışığı da hareket eder.
                Positioned(
                  left: -_glowPad * scale,
                  top: -_glowPad * scale - lift,
                  child: Opacity(
                    opacity: 0.55,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 9 * scale,
                        sigmaY: 9 * scale,
                      ),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [
                            _QuestsScreenState._progressColor,
                            _QuestsScreenState._progressColor,
                          ],
                        ).createShader(rect),
                        child: Image.asset(
                          'assets/icons/ticket.png',
                          width: w + 2 * _glowPad * scale,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bilet + kalınlık bandı **tek gövde**: zıplarken ikisi
                // birlikte kalkar ve aralarındaki `depth` boşluğu korunur.
                // Yalnız bilet zıplayınca band altta açıkta kalıyor ve ayrı
                // bir koyu bilet gibi okunuyordu — band biletin gölgesi
                // değil, kalınlığı.
                //
                // Basılma bunun istisnası: orada ön yüz banda **çöker**
                // (§2.4 depth-press), yani ikisi bilerek üst üste biner.
                Positioned(
                  left: 0,
                  top: -lift,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    // İniş ezilişi: alttan basılmış gibi yayılır. Hacim
                    // korunsun diye yatayda genişleyip dikeyde kısalıyor.
                    // Gruba uygulanır ki band da aynı deformasyonu yaşasın.
                    transform: Matrix4.diagonal3Values(
                      1 + 0.09 * hop.squash,
                      1 - 0.11 * hop.squash,
                      1,
                    ),
                    child: SizedBox(
                      width: w,
                      height: h + depth,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: depth,
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [
                                  _QuestsScreenState._dimGoldColor,
                                  _QuestsScreenState._dimGoldColor,
                                ],
                              ).createShader(rect),
                              child: Image.asset(
                                'assets/icons/ticket.png',
                                width: w,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Talep gönderilirken bilet **yerinde kalır**,
                          // göstergeyi üstüne bindiririz. Eskiden bilet
                          // tamamen kaldırılıp yerine gösterge konuyordu ama
                          // kalınlık bandı duruyordu: geriye içi boş koyu bir
                          // kabuk ve içinde dönen bir çember kalıyordu.
                          Positioned(
                            left: 0,
                            top: _isPressed ? depth : 0,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/ticket.png',
                                    width: w,
                                    fit: BoxFit.contain,
                                  ),
                                  if (widget.isClaiming)
                                    SizedBox(
                                      // 26 birimde (cihazda ~17pt) fark
                                      // edilmiyordu; bilet 76 birim olduğuna
                                      // göre gösterge de okunur olmalı.
                                      width: 38 * scale,
                                      height: 38 * scale,
                                      child: CircularProgressIndicator(
                                        // Altın biletin üstünde koyu kahve —
                                        // §2.9'da altın dolgu üstündeki
                                        // metin için kullanılan ton.
                                        color:
                                            _QuestsScreenState._onProgressColor,
                                        strokeWidth: 3.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  // Rozet de gövdeye bağlı: zıplarken yerinde kalsaydı
                  // biletten kopuk, havada asılı bir sayı gibi görünürdü.
                  // Talep sırasında da durur — kaybolsaydı bilet yerinde
                  // kalırken rozetin sıçraması yeni bir titreme olurdu.
                  // Eziliş uygulanmaz — küçük bir daireyi deforme etmek
                  // "lastik" hissi veriyor, sayı da okunmaz oluyor.
                  child: Transform.translate(
                    offset: Offset(0, -lift),
                    child: Container(
                      width: badge,
                      height: badge,
                      decoration: BoxDecoration(
                        color: _QuestsScreenState._backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _QuestsScreenState._progressColor,
                          width: 2 * scale,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.all(3 * scale),
                          child: Text(
                            '${widget.rewardTickets}',
                            style: TextStyle(
                              color: _QuestsScreenState._textColor,
                              fontFamily: AppTypography.family,
                              fontSize: badge * 0.62,
                              fontWeight: AppTypography.number,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.scale,
    required this.onRetry,
  });

  final double scale;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(40 * scale, 120 * scale, 40 * scale, 0),
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: _QuestsScreenState._mutedTextColor,
          size: 96 * scale,
        ),
        SizedBox(height: 24 * scale),
        Text(
          'Görevler yüklenemedi.\nAşağı çekerek tekrar dene.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _QuestsScreenState._mutedTextColor,
            fontSize: 26 * scale,
            fontWeight: AppTypography.body,
            fontFamily: AppTypography.family,
          ),
        ),
      ],
    );
  }
}

/// Profil/lig kartlarıyla aynı yüzey dili: zemin renginde yüz, üst kenarsız
/// kontur ve altta taban dudağı.
class _QuestSurface extends StatelessWidget {
  const _QuestSurface({
    required this.scale,
    required this.radius,
    required this.child,
  });

  final double scale;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _QuestsScreenState._cardBorderColor,
        borderRadius: BorderRadius.circular(AppShapeStyle.cardRadius(radius)),
      ),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(7 * scale)),
      child: Container(
        decoration: BoxDecoration(
          color: _QuestsScreenState._cardFaceColor,
          borderRadius: BorderRadius.circular(AppShapeStyle.cardRadius(radius)),
        ),
        foregroundDecoration: _NoTopBorderDecoration(
          color: _QuestsScreenState._cardBorderColor,
          strokeWidth: AppShapeStyle.outline(2 * scale),
          radius: AppShapeStyle.cardRadius(radius),
        ),
        child: child,
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

/// Kutlamayı sunucuya dokunmadan tetikleyen tasarım aracı.
///
/// Yalnızca `kDebugMode` altında gösterilir; animasyonu tekrar tekrar izleyip
/// ayarlayabilmek için var. Kutlama tasarımı kesinleşince bu sınıf ve
/// `_playCelebrationDemo` silinecek — kalıcı bir özellik değildir.
class _DemoCelebrationButton extends StatelessWidget {
  const _DemoCelebrationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DepthPressableButton(
      text: 'KUTLAMA',
      width: 132,
      height: 46,
      radius: 14,
      shadowOffset: 5,
      backgroundColor: const Color(0xFF1CB1F5),
      shadowColor: const Color(0xFF1B84B5),
      fontSize: 15,
      fontWeight: AppTypography.action,
      onPressed: onPressed,
    );
  }
}
