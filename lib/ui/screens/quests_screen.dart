import 'package:lingualloop/ui/app_typography.dart';
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
import 'package:lingualloop/ui/widgets/clock_mark.dart';
import 'package:lingualloop/ui/widgets/hop_motion.dart';
import 'package:lingualloop/ui/widgets/loading_skeleton.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_flake.dart';
import 'package:lingualloop/ui/widgets/surface_gloss.dart';
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
  static const _cardBorderColor = Color(0xFF0B2143);
  static const _iconTileColor = Color(0xFF0C2244);
  static const _progressColor = Color(0xFFFFC93A);

  /// Kuponun tonları (§2.2): yüz iç panel `0C2244`, kalınlık ve boş adım
  /// yuvası onun koyusu `07182F`, ödülü hazır koçan vurgulu satır `163258`.
  static const _couponFace = Color(0xFF0C2244);
  static const _couponDepth = Color(0xFF07182F);
  static const _stubOpen = Color(0xFF163258);

  /// Henüz kazanılmamış ödülün tonu. Palet dışı değil: §2.6'daki `yildiz`
  /// lig taşının koyu tonu, yani bilet altınının belgeli koyusu.
  static const _dimGoldColor = Color(0xFFB87E00);
  static const _onProgressColor = Color(0xFF4A3400);
  static const _textColor = Colors.white;
  static const _mutedTextColor = Color(0xFF8FA0B5);
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
      // Sekmeler her geçişte yeniden kurulur: görevler eldeyse ekran
      // beklemeden gelir, arkada tazelenir (ana ekran ve Ligler gibi).
      final quests = context.read<QuestsProvider>();
      quests.load(silent: quests.data != null);
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

  /// Günün bütün görevleri bitince seri korumasını toplar. Kutlama perdesi
  /// açılmaz: hedef kartındaki koruma onaylanır, sayısı üst şeritte artar.
  Future<void> _claimFreeze() async {
    final result = await context.read<QuestsProvider>().claimFreeze();
    if (result == null || !mounted) return;

    if (result.blockedByCap) {
      // Talep tüketilmedi: koruma harcanınca aynı gün yine alınabilir.
      AppNotifier.showMessage(
        'En fazla ${result.freezeCap} seri koruması tutulabilir.',
        color: _iconTileColor,
      );
      return;
    }
    if (!result.claimed) return;

    AppNotifier.showMessage('Seri koruması alındı.', color: _iconTileColor);
    // Koruma sayısı ana ekranın üst şeridiyle senkron kalsın.
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
                    return _QuestsSkeleton(scale: scale);
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
                      14 * scale,
                      34 * scale,
                      54 * scale,
                    ),
                    children: [
                      _QuestsTopBar(
                        scale: scale,
                        iconKey: _ticketIconKey,
                        pendingTickets: _pendingTickets,
                        fly: _flyController,
                        flyingCount: _flyingCount,
                      ),
                      if (quests.isNotEmpty) ...[
                        SizedBox(height: 22 * scale),
                        _GoalSceneCard(
                          scale: scale,
                          quests: quests,
                          freezeBonus: data?.freezeBonus,
                          claimingFreeze: provider.claimingFreeze,
                          onClaimFreeze: _claimFreeze,
                        ),
                      ],
                      SizedBox(height: 36 * scale),
                      _SectionLabel(
                        'GÜNLÜK GÖREVLER',
                        scale: scale,
                        trailing: _ResetCountdown(
                          scale: scale,
                          resetAtUtc: data?.resetAtUtc,
                        ),
                      ),
                      SizedBox(height: 14 * scale),
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

  /// Görev kuponlarını konumlarını hesaplayarak yerleştirir: ödülü alınanlar
  /// "TAMAMLANANLAR" başlığının altına koçanı koparılmış hâlde kayar. Kupon
  /// boyları sabit olduğu için hedef konumlar hesaplanabiliyor ve geçiş
  /// animasyonlu olur.
  Widget _buildQuestBoard(
    List<DailyQuest> quests,
    double scale,
    QuestsProvider provider,
  ) {
    const animationDuration = Duration(milliseconds: 420);
    final activeHeight = _QuestCoupon.totalHeight(scale);
    final completedHeight = _TornCoupon.height * scale;
    final activeGap = 18 * scale;
    final completedGap = 14 * scale;
    final sectionHeaderHeight = 72 * scale;
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
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 14 * scale),
                    child: _SectionLabel('TAMAMLANANLAR', scale: scale),
                  ),
                ),
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
                child: quest.isClaimed
                    ? _TornCoupon(scale: scale, quest: quest)
                    : _QuestCoupon(
                        scale: scale,
                        quest: quest,
                        // Ödül uçuşunun kaynağı koçandaki bilet; konumu
                        // talep anında bu anahtarla ölçülüyor.
                        stubKey: _cardKey(quest.questKey),
                        isClaiming: provider.isClaiming(quest.questKey),
                        onClaim: () => _claim(quest.questKey),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Üst satır: ekranın adı ve bilet bakiyesi. Bakiye uçan biletlerin hedefi.
class _QuestsTopBar extends StatelessWidget {
  const _QuestsTopBar({
    required this.scale,
    required this.iconKey,
    required this.pendingTickets,
    required this.fly,
    required this.flyingCount,
  });

  final double scale;
  final GlobalKey iconKey;
  final int pendingTickets;
  final Animation<double> fly;
  final int flyingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Dar ekranda sayaca yer bırakır: sığmazsa küçülür, kesilmez.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Görevler',
              maxLines: 1,
              style: TextStyle(
                color: _QuestsScreenState._textColor,
                fontSize: 46 * scale,
                fontWeight: AppTypography.heading,
                fontFamily: AppTypography.displayFamily,
                height: 1.05,
              ),
            ),
          ),
        ),
        SizedBox(width: 14 * scale),
        // Bayrak yerine bilet sayacı: başlıkta dekoratif bir simge yerine
        // **durumu değişen** bir sayı duruyor. Uçan biletlerin hedefi de burası.
        _TicketCounter(
          scale: scale,
          ticketWidth: 84,
          pendingTickets: pendingTickets,
          iconKey: iconKey,
          fly: fly,
          flyingCount: flyingCount,
        ),
      ],
    );
  }
}

/// Günün hedefi (15 Kas 2026, kullanıcı onayı — taslak A): sahneli kart.
/// Solda hedef, her görev için bir adım ve sonunda ödül olan seri koruması;
/// sağda maskot sahnesi. Ekranın odağı bu kart: önceki tasarımda beş eş kart
/// alt alta duruyor, hiçbiri öne çıkmıyordu (`docs/GOREVLER_ARASTIRMA.md`).
///
/// Kuruluş seri penceresindeki sahneli kartla aynı: görsel sola doğru kendi
/// alfasıyla kartın rengine söner, kart rengi sahneden **ölçülür** (§5
/// "Güne/duruma özel seri kartları"). Turuncu keyfî değil, sahnenin rengi.
///
/// Sahne görevlere özel (15 Kas 2026, `docs/GOREVLER_SAHNE_PROMPT.md`):
/// altın bandanalı maskot sola, kartın solundaki adımlara ve seri
/// korumasına doğru koşuyor. Kart "Tüm görevleri bitir" diyor; vaat sonuç
/// değil eylem (yerini aldığı kupa sahnesi sonucu anlatıyordu).
class _GoalSceneCard extends StatelessWidget {
  const _GoalSceneCard({
    required this.scale,
    required this.quests,
    required this.freezeBonus,
    required this.claimingFreeze,
    required this.onClaimFreeze,
  });

  final double scale;
  final List<DailyQuest> quests;
  final QuestFreezeBonus? freezeBonus;
  final bool claimingFreeze;
  final VoidCallback onClaimFreeze;

  /// Kart yüzü ve sağ ucu: sahneden ölçüldü (sol kenar `FC8B31`, sağ
  /// kenarın ortası `FC7838`). Görsel sola doğru söndüğü için kartın sol
  /// yarısı sahnenin kendi zemin tonunda; arada dikiş kalmıyor.
  static const face = Color(0xFFFC8B31);
  static const _edge = Color(0xFFFC7838);
  static const _runScene = 'assets/scenes/gorev_hedefi.png';

  /// Beş görev de bitince: maskot bitiş kapısından, şeridi koparıp çıkıyor.
  /// Koşu sahnesiyle aynı dünya (zemin `FC8E2F`/`FD7A33`, ±3 ton): kart rengi
  /// ve yerleşim değişmeden sahne değişir. Kapı görselin %53–97'sinde;
  /// uzun alt yazı sol direğe dayandığı için bitmiş durumun yazısı kısa
  /// ("Hepsini bitirdin!", "Seri koruması alındı").
  static const _finishScene = 'assets/scenes/gorev_bitis.png';

  /// Sahnenin kutusu: eni kart boyunun katı ve sağdan taşma (birim).
  /// Ölçüldü: maskot görselin %54–96'sında (sol yumruk ile toz bulutları).
  /// Kupa sahnesinin ölçüleriyle (1.78, 40) toz bulutları ve bandananın ucu
  /// kartın sağ kenarında kırpılıyordu; %8 küçültüp sağa yaslayınca iki
  /// yanda pay kalıyor, yumruk koruma karosuna değmiyor.
  static const _sceneWidth = 1.633;
  static const _sceneOverflow = 5.0;

  /// Kartın boyu (tasarım birimi).
  static const height = 300.0;

  /// Biten görev sayılır, ödülü alınmasa da: seri koruması da bitene bakar
  /// (bilet tavanındaki kullanıcı ödül alamasa bile korumayı kazanır).
  int get _done => quests.where((q) => q.isCompleted || q.isClaimed).length;

  bool get _freezeShown => freezeBonus != null && freezeBonus!.total > 0;

  bool get _allDone => quests.isNotEmpty && _done >= quests.length;

  /// Koruma alınmayı bekliyor: alt yazının yerinde çağrı düğmesi durur.
  bool get _freezeReady =>
      _freezeShown && freezeBonus!.unlocked && !freezeBonus!.claimed;

  String _caption() {
    final head = '$_done/${quests.length} görev';
    final bonus = freezeBonus;
    if (bonus == null || !_freezeShown) return head;
    if (bonus.claimed) return 'Seri koruması alındı';
    return '$head · ödül: seri koruması';
  }

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = height * s;
    final r = 36 * s;
    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [face, _edge],
                    stops: [0.45, 1],
                  ),
                ),
              ),
            ),
            // Sahne sağda; sola doğru kendi alfasıyla söner (seri kartındaki
            // gibi üstüne kart renginde katman konmaz, sınırda çizgi kalır).
            Positioned(
              right: -_sceneOverflow * s,
              top: -6 * s,
              bottom: -6 * s,
              width: h * _sceneWidth,
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.34],
                  ).createShader(rect),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Image.asset(
                      _allDone ? _finishScene : _runScene,
                      key: ValueKey(_allDone),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TopRimPainter(
                    color: Colors.white.withValues(alpha: 0.42),
                    radius: r,
                    strokeWidth: 3 * s,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 34 * s,
              top: 30 * s,
              width: 372 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUGÜNÜN HEDEFİ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 20 * s,
                      fontWeight: AppTypography.number,
                      fontFamily: AppTypography.family,
                      letterSpacing: 1.6 * s,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    _allDone ? 'Hepsini bitirdin!' : 'Tüm görevleri bitir',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35 * s,
                      fontWeight: AppTypography.heading,
                      fontFamily: AppTypography.displayFamily,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 26 * s),
                  Row(
                    children: [
                      for (var i = 0; i < quests.length; i++) ...[
                        if (i > 0) SizedBox(width: 9 * s),
                        // Karonun yüzü kalınlık kadar yukarıda: kareler
                        // satırın değil yüzün ortasına hizalanır.
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _freezeShown ? _FreezeReward.depth * s : 0,
                          ),
                          child: _StepPip(scale: s, done: i < _done),
                        ),
                      ],
                      if (_freezeShown) ...[
                        SizedBox(width: 12 * s),
                        _FreezeReward(
                          // Testin dokunabilmesi için sabit anahtar.
                          key: const ValueKey('claim-freeze'),
                          scale: s,
                          ready: freezeBonus!.unlocked,
                          claimed: freezeBonus!.claimed,
                          isClaiming: claimingFreeze,
                          onPressed: onClaimFreeze,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 18 * s),
                  if (_freezeReady)
                    _FreezeReadyChip(
                      key: const ValueKey('claim-freeze-chip'),
                      scale: s,
                      enabled: !claimingFreeze,
                      onPressed: onClaimFreeze,
                    )
                  else
                    Text(
                      _caption(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 21 * s,
                        fontWeight: AppTypography.label,
                        fontFamily: AppTypography.family,
                        height: 1.15,
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

/// "Seri koruması hazır": kartın tek eylem çağrısı. Beyaz alt yazı kartın
/// geri kalanıyla aynı sesle konuşuyordu (kullanıcı: "farklı bir renk
/// olsun, dikkat çeksin, haber versin"). Kap koruma karosunun açık
/// malzemesi (`163258`/`0B2143`), yazı buzun rengi (`StreakFreezeFlake`
/// yüzü `9BDCF4`): yazı ile yanındaki karo aynı nesneyi gösterir.
/// Düğme olduğu için basılır; işi karoyla aynı: korumayı alır.
class _FreezeReadyChip extends StatelessWidget {
  const _FreezeReadyChip({
    super.key,
    required this.scale,
    required this.enabled,
    required this.onPressed,
  });

  final double scale;
  final bool enabled;
  final VoidCallback onPressed;

  static const _ice = Color(0xFF9BDCF4);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: 'Seri koruması hazır, al',
      excludeSemantics: true,
      child: DepthPressableButton(
        width: 268 * s,
        height: 50 * s,
        radius: 15 * s,
        shadowOffset: 7 * s,
        backgroundColor: _QuestsScreenState._stubOpen,
        shadowColor: _QuestsScreenState._cardBorderColor,
        fontSize: 21 * s,
        enabled: enabled,
        onPressed: onPressed,
        child: Text(
          'Seri koruması hazır',
          maxLines: 1,
          style: TextStyle(
            color: _ice,
            fontSize: 21 * s,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Hedef kartındaki görev adımı: biten beyaz ve onaylı, kalan beyazın
/// soluk izi. Onay işaretinin rengi kartın kendi rengi.
class _StepPip extends StatelessWidget {
  const _StepPip({required this.scale, required this.done});

  final double scale;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final size = 38 * scale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: done ? Colors.white : Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(11 * scale),
      ),
      child: done
          ? const CustomPaint(
              painter: _PipCheckPainter(color: _GoalSceneCard.face),
            )
          : null,
    );
  }
}

class _PipCheckPainter extends CustomPainter {
  const _PipCheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    canvas.drawPath(
      Path()
        ..moveTo(28 * u, 52 * u)
        ..lineTo(44 * u, 67 * u)
        ..lineTo(73 * u, 35 * u),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PipCheckPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bölüm başlığı: büyük harf, sönük, harf aralıklı (Duolingo'nun "DAILY
/// QUESTS" satırı gibi); sağında isteğe bağlı bir değer.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.scale, this.trailing});

  final String text;
  final double scale;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _QuestsScreenState._mutedTextColor,
                fontSize: 21 * scale,
                fontWeight: AppTypography.number,
                fontFamily: AppTypography.family,
                letterSpacing: 1.6 * scale,
                height: 1.15,
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 12 * scale),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Görevlerin yenilenmesine kalan süre, bölüm başlığının sağında (Duolingo
/// da günlük görevlerin başlığına yalnız "⏱ 5 HOURS" yazar). Saat §2.5
/// reçeteli `ClockMark`. §2.10: son 2 saatte saat ve değer sıcak tona geçer.
class _ResetCountdown extends StatelessWidget {
  const _ResetCountdown({required this.scale, required this.resetAtUtc});

  final double scale;
  final DateTime? resetAtUtc;

  static const _urgentColor = Color(0xFFFF6B3D);

  Duration? get _remaining => resetAtUtc?.difference(DateTime.now().toUtc());

  bool get _urgent {
    final remaining = _remaining;
    return remaining != null &&
        !remaining.isNegative &&
        remaining.inMinutes <= 120;
  }

  /// Büyük harf elle yazılır: `toUpperCase` Türkçe "i"yi "I" yapıyor.
  String get _value {
    final remaining = _remaining;
    if (remaining == null) return '';
    if (remaining.isNegative) return 'YENİLENİYOR';
    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes - remaining.inHours * 60;
      return '${remaining.inHours} SA $minutes DK';
    }
    return '${remaining.inMinutes} DK';
  }

  String get _spoken {
    final remaining = _remaining;
    if (remaining == null || remaining.isNegative) {
      return 'Görevler yenileniyor';
    }
    final minutes = remaining.inMinutes - remaining.inHours * 60;
    return remaining.inHours > 0
        ? 'Görevler ${remaining.inHours} saat $minutes dakika sonra yenilenir'
        : 'Görevler ${remaining.inMinutes} dakika sonra yenilenir';
  }

  @override
  Widget build(BuildContext context) {
    if (resetAtUtc == null) return const SizedBox.shrink();
    final urgent = _urgent;
    return Semantics(
      label: _spoken,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClockMark(size: 28 * scale, urgent: urgent),
          SizedBox(width: 8 * scale),
          Text(
            _value,
            style: TextStyle(
              color: urgent ? _urgentColor : _QuestsScreenState._mutedTextColor,
              fontSize: 21 * scale,
              fontWeight: AppTypography.number,
              fontFamily: AppTypography.family,
              letterSpacing: 1.2 * scale,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

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
    this.ticketWidth = 100,
    required this.pendingTickets,
    required this.iconKey,
    required this.fly,
    required this.flyingCount,
  });

  final double scale;

  /// Biletin eni (tasarım birimi).
  final double ticketWidth;
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
                    width: ticketWidth * scale,
                    height: ticketWidth * scale * 110 / 172 + 6 * scale,
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
                              width: ticketWidth * scale,
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
                            width: ticketWidth * scale,
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

/// Kupon biçimi: köşeleri yuvarlak dikdörtgen, koçan çizgisinde üstte ve
/// altta yarım daire çentik (bilet simgesinin çentiklerinin dili).
Path _couponPath(Size size, double radius, double stubX, double notch) {
  final base = Path()
    ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
  final cuts = Path()
    ..addOval(Rect.fromCircle(center: Offset(stubX, 0), radius: notch))
    ..addOval(
        Rect.fromCircle(center: Offset(stubX, size.height), radius: notch));
  return Path.combine(PathOperation.difference, base, cuts);
}

/// Kuponun yüzü, kalınlığı, koçanı ve yırtma çizgisi.
class _CouponPainter extends CustomPainter {
  const _CouponPainter({
    required this.scale,
    required this.stubWidth,
    required this.band,
    required this.face,
    required this.depth,
    required this.stubFace,
  });

  final double scale;
  final double stubWidth;
  final double band;
  final Color face;
  final Color depth;
  final Color stubFace;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final bandHeight = band * s;
    final faceSize = Size(size.width, size.height - bandHeight);
    final notch = 15 * s;
    final stubX = size.width - stubWidth * s;
    final shape = _couponPath(faceSize, 28 * s, stubX, notch);

    // Kalınlık: aynı biçim aşağı kaydırılmış (§2.4 dili). Alt çentik bandı
    // da boydan boya keser; yoksa bandın ucu çentiğin içinde leke kalıyor.
    final through = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(stubX - notch, faceSize.height - notch, stubX + notch,
            faceSize.height + bandHeight + notch),
        Radius.circular(notch),
      ));
    canvas.drawPath(
      Path.combine(PathOperation.difference, shape.shift(Offset(0, bandHeight)),
          through),
      Paint()..color = depth,
    );
    canvas.drawPath(shape, Paint()..color = face);

    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
      Rect.fromLTWH(stubX, 0, size.width - stubX, faceSize.height),
      Paint()..color = stubFace,
    );
    canvas.restore();

    // Yırtma çizgisi: sayfa zemininin renginde kısa çizgiler.
    final dash = Paint()
      ..color = _QuestsScreenState._backgroundColor
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    for (var y = notch + 10 * s;
        y < faceSize.height - notch - 8 * s;
        y += 16 * s) {
      canvas.drawLine(Offset(stubX, y), Offset(stubX, y + 7 * s), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _CouponPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.stubWidth != stubWidth ||
      oldDelegate.band != band ||
      oldDelegate.face != face ||
      oldDelegate.depth != depth ||
      oldDelegate.stubFace != stubFace;
}

/// Görev kuponu (15 Kas 2026, kullanıcı onayı — taslak A1). Solda görev ve
/// adımları, sağdaki koçanda ödül bileti. Koçan çizgisindeki kesik çizgi ve
/// çentikler bilet simgesinin çentiklerinden: görev biletle ödüllendiriliyor,
/// kartın biçimi bunu söylüyor. Önceki kontur kart + sarı çubuk yapısının
/// yerine geçti.
///
/// Ödül hazırsa koçan açılır (`163258`), bilet zıplar (`_ClaimButton`,
/// §5 "sönükten parlağa") ve altında "AL" yazar; koçanın tamamı dokunulur.
/// Alınınca kupon koçanı koparılmış hâliyle "Tamamlananlar"a iner
/// ([_TornCoupon]).
class _QuestCoupon extends StatelessWidget {
  const _QuestCoupon({
    required this.scale,
    required this.quest,
    required this.stubKey,
    required this.isClaiming,
    required this.onClaim,
  });

  final double scale;
  final DailyQuest quest;

  /// Koçanın anahtarı: ödül uçuşu buradan kalkar.
  final GlobalKey stubKey;
  final bool isClaiming;
  final VoidCallback onClaim;

  static const _faceHeight = 150.0;
  static const band = 8.0;
  static const stubWidth = 148.0;

  /// Kupon yüzü + kalınlık. Pano konumları bu sabite dayanır.
  static double totalHeight(double scale) => (_faceHeight + band) * scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final ready = quest.isCompleted;
    return CustomPaint(
      painter: _CouponPainter(
        scale: s,
        stubWidth: stubWidth,
        band: band,
        face: _QuestsScreenState._couponFace,
        depth: _QuestsScreenState._couponDepth,
        stubFace: ready
            ? _QuestsScreenState._stubOpen
            : _QuestsScreenState._couponFace,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: band * s),
        child: Row(
          children: [
            SizedBox(width: 24 * s),
            QuestIcon(questKey: quest.questKey, size: 62 * s),
            SizedBox(width: 20 * s),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _QuestsScreenState._textColor,
                      fontSize: 25 * s,
                      fontWeight: AppTypography.label,
                      fontFamily: AppTypography.family,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 14 * s),
                  _QuestPips(
                    scale: s,
                    progress: quest.progress,
                    target: quest.target,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * s),
            SizedBox(
              key: stubKey,
              width: stubWidth * s,
              height: _faceHeight * s,
              child: ready ? _readyStub(s) : _waitingStub(s),
            ),
          ],
        ),
      ),
    );
  }

  /// Bekleyen ödül kısık: opak koyu altın bilet ve adet (§5).
  ///
  /// Bilet ile rozet tek kutu ve rozet biletin sağ altına taşıyor; kutuyu
  /// ortalamak bilet gövdesini sol üste kaydırıyordu (biletler "yukarı
  /// kayık" görünüyordu, kullanıcı fark etti). Kutu taşma kadar sağa ve
  /// aşağı itilir, **gövde** koçanın ortasına gelir (bilet bitti
  /// penceresindeki optik ortalamanın aynısı).
  Widget _waitingStub(double s) {
    const badge = 30.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: badge * 0.42 * s, top: badge * 0.34 * s),
        child: TicketWithCount(
          scale: s,
          count: quest.rewardTickets,
          ticketWidth: 62,
          badgeSize: badge,
          dim: true,
        ),
      ),
    );
  }

  /// Hazır ödül: koçanın tamamı dokunulur, bilet kendi basma hareketiyle.
  Widget _readyStub(double s) => Semantics(
        button: true,
        label: 'Ödülü al: ${quest.rewardTickets} bilet',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isClaiming ? null : onClaim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rozet sağa taştığı için kutu ortalanınca bilet "AL"ın soluna
              // kayıyordu; taşma kadar sağa itilir, gövde yazının üstünde.
              Padding(
                padding: EdgeInsets.only(left: 32 * 0.42 * s),
                child: _ClaimButton(
                  // Testin dokunabilmesi için sabit anahtar: talep gönderme
                  // durumu ancak dokunarak üretilebiliyor ve o durumun
                  // golden'ı olmadığı için iki hata canlıya kadar gitmişti
                  // (bkz. quest_claim_pending_test).
                  key: ValueKey('claim-${quest.questKey}'),
                  scale: s,
                  rewardTickets: quest.rewardTickets,
                  isClaiming: isClaiming,
                  onPressed: onClaim,
                ),
              ),
              SizedBox(height: 6 * s),
              Text(
                'AL',
                style: TextStyle(
                  color: _QuestsScreenState._progressColor,
                  fontSize: 22 * s,
                  fontWeight: AppTypography.number,
                  fontFamily: AppTypography.family,
                  letterSpacing: 1.4 * s,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Görevin adımları: hedef kartındaki adım karelerinin dili. Biten altın
/// (görev ilerlemesi bilet altını, §5), kalan koyu yuva; yanında sayı.
/// Hedef büyüdükçe kareler sığacak kadar küçülür (10 kelimelik görev).
class _QuestPips extends StatelessWidget {
  const _QuestPips({
    required this.scale,
    required this.progress,
    required this.target,
  });

  final double scale;
  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final done = progress.clamp(0, target < 0 ? 0 : target);
    final label = Text(
      '$done/$target',
      maxLines: 1,
      style: TextStyle(
        color: _QuestsScreenState._mutedTextColor,
        fontSize: 20 * s,
        fontWeight: AppTypography.number,
        fontFamily: AppTypography.family,
        height: 1.15,
      ),
    );
    if (target <= 0) return label;
    final gap = 7 * s;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            (constraints.maxWidth - 70 * s - gap * (target - 1)) / target;
        final size = math.max(10 * s, math.min(22 * s, fit));
        return Row(
          children: [
            for (var i = 0; i < target; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: i < done
                      ? _QuestsScreenState._progressColor
                      : _QuestsScreenState._couponDepth,
                  borderRadius: BorderRadius.circular(size * 0.3),
                ),
              ),
            ],
            SizedBox(width: 12 * s),
            label,
          ],
        );
      },
    );
  }
}

/// Ödülü alınmış görev: koçanı koparılmış kupon. Sağ kenar tırtıklı
/// (yırtma çizgisinin yarısı), koçanın yeri boş; ödül ve onay gövdenin
/// içinde. Sönük tonlu ve düz: işi bitmiş, dikkat aktif görevlerde kalsın.
class _TornCoupon extends StatelessWidget {
  const _TornCoupon({required this.scale, required this.quest});

  final double scale;
  final DailyQuest quest;

  /// Yükseklik (tasarım birimi); pano konumları buna dayanır.
  static const height = 96.0;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      // Koçanın yeri boş kalır; pay, uzun başlık ("2 rövanş kartını geri
      // kazan") kesilmeyecek kadar dar.
      padding: EdgeInsets.only(right: 64 * s),
      child: CustomPaint(
        painter: _TornPainter(scale: s, color: _QuestsScreenState._couponDepth),
        child: Padding(
          padding: EdgeInsets.only(right: 26 * s),
          child: Row(
            children: [
              SizedBox(width: 24 * s),
              Opacity(
                opacity: 0.55,
                child: QuestIcon(questKey: quest.questKey, size: 44 * s),
              ),
              SizedBox(width: 20 * s),
              Expanded(
                child: Text(
                  quest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _QuestsScreenState._mutedTextColor,
                    fontSize: 23 * s,
                    fontWeight: AppTypography.label,
                    fontFamily: AppTypography.family,
                  ),
                ),
              ),
              Text(
                '+${quest.rewardTickets}',
                style: TextStyle(
                  color: _QuestsScreenState._mutedTextColor,
                  fontSize: 21 * s,
                  fontWeight: AppTypography.number,
                  fontFamily: AppTypography.family,
                ),
              ),
              SizedBox(width: 10 * s),
              QuestCheckMark(size: 40 * s),
            ],
          ),
        ),
      ),
    );
  }
}

class _TornPainter extends CustomPainter {
  const _TornPainter({required this.scale, required this.color});

  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 28 * scale;
    final bite = 7 * scale;
    final body = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: Radius.circular(r),
        bottomLeft: Radius.circular(r),
      ));
    final bites = Path();
    for (var y = bite; y < size.height; y += bite * 2.6) {
      bites.addOval(
          Rect.fromCircle(center: Offset(size.width, y), radius: bite));
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, body, bites),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TornPainter oldDelegate) =>
      oldDelegate.scale != scale || oldDelegate.color != color;
}

/// Günün hedefinin ödülü: hedef kartındaki adımların vardığı lacivert
/// düğüm karosu, içinde seri koruması. Buz mavisi alev turuncu kartta ancak
/// lacivert bir karonun içinde seçiliyor. Bütün görevler bitmeden karo
/// kapalı tonda, koruma soluk; hazır olunca karo açılır ve zıplar
/// (`HopMotion`, "buraya dokun"); alınınca köşesinde onay. Talep sürerken
/// zıplama durur, üstünde gösterge döner. Yazısı olmadığı için dokununca ne
/// olduğunu söyler.
class _FreezeReward extends StatefulWidget {
  const _FreezeReward({
    super.key,
    required this.scale,
    required this.ready,
    required this.claimed,
    required this.isClaiming,
    required this.onPressed,
  });

  /// Karonun eni (kalınlık dahil boyu da bu). Dokunma hedefi ≈44pt.
  static const boxSize = 74.0;
  static const depth = 7.0;

  final double scale;
  final bool ready;
  final bool claimed;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  State<_FreezeReward> createState() => _FreezeRewardState();
}

class _FreezeRewardState extends State<_FreezeReward>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop =
      AnimationController(vsync: this, duration: HopMotion.duration);

  bool get _hopping => widget.ready && !widget.claimed && !widget.isClaiming;

  @override
  void initState() {
    super.initState();
    if (_hopping) _hop.repeat();
  }

  @override
  void didUpdateWidget(covariant _FreezeReward oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hopping && !_hop.isAnimating) {
      _hop.repeat();
    } else if (!_hopping && _hop.isAnimating) {
      // Durduğu yerde donmasın, yere otursun (bilet ödülündeki ders).
      _hop.stop();
      _hop.value = 0;
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isClaiming) return;
    if (widget.claimed) {
      AppNotifier.showMessage(
        'Bugünün seri koruması alındı.',
        color: _QuestsScreenState._iconTileColor,
      );
      return;
    }
    if (!widget.ready) {
      AppNotifier.showMessage(
        'Seri koruması tüm görevler bitince alınabilir.',
        color: _QuestsScreenState._iconTileColor,
      );
      return;
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final box = _FreezeReward.boxSize * scale;
    return Semantics(
      button: true,
      label: 'Seri koruması',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SizedBox(
          width: box,
          height: box,
          child: AnimatedBuilder(
            animation: _hop,
            builder: (context, child) {
              final hop = HopMotion.at(_hop.value);
              return Transform.translate(
                offset: Offset(0, -hop.lift * HopMotion.height * scale),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: HopMotion.squash(hop.squash),
                  child: child,
                ),
              );
            },
            child: _node(scale, box),
          ),
        ),
      ),
    );
  }

  /// Karo: yüz + altında koyu kalınlık; zıplarken ikisi birlikte kalkar.
  Widget _node(double scale, double box) {
    final open = widget.ready || widget.claimed;
    final depth = _FreezeReward.depth * scale;
    final radius = BorderRadius.circular(box * 0.29);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: depth,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: open
                  ? _QuestsScreenState._cardBorderColor
                  : _QuestsScreenState._couponDepth,
              borderRadius: radius,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: depth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: open
                  ? _QuestsScreenState._stubOpen
                  : _QuestsScreenState._couponFace,
              borderRadius: radius,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (open)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FaceGlossPainter(radius: box * 0.29),
                    ),
                  ),
                Opacity(
                  opacity: open ? 1 : 0.6,
                  child: StreakFreezeFlake(size: box * 0.74),
                ),
                if (widget.isClaiming)
                  SizedBox(
                    width: 28 * scale,
                    height: 28 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.claimed)
          Positioned(
            right: -8 * scale,
            bottom: -4 * scale,
            child: QuestCheckMark(size: 34 * scale),
          ),
      ],
    );
  }
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

  /// Hâlenin biletten her yöne taşma payı (tasarım birimi).
  static const _glowPad = 13.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: HopMotion.duration,
    );
    if (!widget.isClaiming) _pulse.repeat();
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
            final hop = _isPressed
                ? (lift: 0.0, squash: 0.0)
                : HopMotion.at(_pulse.value);
            final lift = hop.lift * HopMotion.height * scale;
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
                    transform: HopMotion.squash(hop.squash),
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

/// Görevler ilk kez inerken: üst satır, hedef kartı ve dört kupon, içleri
/// boş. Veri ana ekranla birlikte indiği için çoğunlukla hiç görünmez.
class _QuestsSkeleton extends StatelessWidget {
  const _QuestsSkeleton({required this.scale});

  final double scale;

  /// Görev başlıklarının kabaca boyları: hepsi aynı olsa liste çizgili
  /// kâğıt gibi duruyor.
  static const _titleWidths = [250.0, 300.0, 320.0, 220.0];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    const inner = _QuestsScreenState._couponDepth;
    return SkeletonReveal(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(34 * s, 14 * s, 34 * s, 54 * s),
        children: [
          Row(
            children: [
              SkeletonBlock(width: 220 * s, height: 46 * s, radius: 12 * s),
              const Spacer(),
              SkeletonBlock(width: 84 * s, height: 54 * s, radius: 12 * s),
              SizedBox(width: 10 * s),
              SkeletonBlock(width: 70 * s, height: 36 * s, radius: 10 * s),
            ],
          ),
          SizedBox(height: 22 * s),
          SkeletonBlock(height: _GoalSceneCard.height * s, radius: 36 * s),
          SizedBox(height: 36 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            child: Row(
              children: [
                SkeletonBlock(width: 230 * s, height: 22 * s, radius: 7 * s),
                const Spacer(),
                SkeletonBlock(width: 150 * s, height: 22 * s, radius: 7 * s),
              ],
            ),
          ),
          SizedBox(height: 14 * s),
          for (final (index, titleWidth) in _titleWidths.indexed) ...[
            if (index > 0) SizedBox(height: 18 * s),
            SizedBox(
              height: _QuestCoupon.totalHeight(s),
              child: CustomPaint(
                painter: _CouponPainter(
                  scale: s,
                  stubWidth: _QuestCoupon.stubWidth,
                  band: _QuestCoupon.band,
                  face: _QuestsScreenState._couponFace,
                  depth: _QuestsScreenState._couponDepth,
                  stubFace: _QuestsScreenState._couponFace,
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: _QuestCoupon.band * s),
                  child: Row(
                    children: [
                      SizedBox(width: 24 * s),
                      SkeletonBlock(
                          width: 62 * s,
                          height: 62 * s,
                          radius: 18 * s,
                          color: inner),
                      SizedBox(width: 20 * s),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBlock(
                                width: titleWidth * s,
                                height: 25 * s,
                                radius: 8 * s,
                                color: inner),
                            SizedBox(height: 14 * s),
                            SkeletonBlock(
                                width: 160 * s,
                                height: 22 * s,
                                radius: 7 * s,
                                color: inner),
                          ],
                        ),
                      ),
                      SizedBox(width: (12 + _QuestCoupon.stubWidth) * s),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
