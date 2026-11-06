import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/flows/ticketed_game_flow.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/screens/karty_unit_unlock_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:provider/provider.dart';

/// `/kartypath` rotası: Karty Yolu'nun verisini yükler ve tazeler, DEVAM'da
/// bileti harcayıp oyunu açar. Görünüş [KartyPathScreen]'de.
///
/// Veri dört yoldan tazelenir (§3.1): açılış, oyundan dönüş (`didPopNext`),
/// uygulamaya dönüş ve aşağı çekme. Ağ hatası ekranı bozmaz; eldeki son
/// veriyle devam edilir.
///
/// Tazelenen veride bekleyen bir ünite açılışı varsa önce kutlama ekranı
/// ([KartyUnitUnlockScreen]) açılır; DEVAM ET'ten sonra patika kamerayı
/// açılan üniteye kaydırır ve açılışı yerinde oynatır.
class KartyPathPage extends StatefulWidget {
  const KartyPathPage({super.key});

  @override
  State<KartyPathPage> createState() => _KartyPathPageState();
}

class _KartyPathPageState extends State<KartyPathPage>
    with WidgetsBindingObserver, RouteAware {
  ModalRoute<void>? _subscribedRoute;
  bool _starting = false;

  /// Gelişi süren ünite; patika onu açılmamış gibi çizer.
  int? _arrivalUnit;
  bool _playArrival = false;

  /// Bu sayfada kutlaması gösterilen ünite: onay yeniden yüklenmeden önceki
  /// tazelemeler aynı kutlamayı ikinci kez açmasın.
  int? _shownUnlock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<KartyPathProvider>();
      unawaited(provider
          .load(silent: provider.data != null)
          .then((_) => _maybeShowUnlock()));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _subscribedRoute) {
      if (_subscribedRoute != null) routeObserver.unsubscribe(this);
      routeObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Oyundan ya da Rövanş'tan dönüldü: bugünün halkası ve bilet değişti.
  @override
  void didPopNext() => unawaited(_refresh());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gece yarısı geçmiş olabilir: bugün/yarın kayar.
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final userService = context.read<UserService>();
    final provider = context.read<KartyPathProvider>();
    await Future.wait([
      provider.load(silent: true),
      userService.scoreWithLivesById(context),
    ]);
    if (mounted) unawaited(_maybeShowUnlock());
  }

  /// Bekleyen ünite açılışını gösterir: patika üniteyi açılmamış gibi
  /// çizer, kutlama ekranı açılır; DEVAM ET'ten sonra kamera üniteye kayar
  /// ve açılış patikada oynar. Patika o sırada en üstteki ekran değilse
  /// (oyun açıkken tazelendiyse) dönüşte yakalanır.
  Future<void> _maybeShowUnlock({KartyUnitUnlock? simulated}) async {
    final response = context.read<KartyPathProvider>().data;
    if (!mounted || response == null || _arrivalUnit != null) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final unlock = simulated ??
        KartyPathData.fromResponse(response, tickets: 0).pendingUnlock;
    if (unlock == null) return;
    if (simulated == null && _shownUnlock == unlock.unlocked.number) return;
    _shownUnlock = unlock.unlocked.number;

    setState(() => _arrivalUnit = unlock.unlocked.number);
    final kartyService = context.read<KartyService>();
    final route = MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => KartyUnitUnlockScreen(
        unlock: unlock,
        // Tasarım simülasyonu gerçek kaydı kapatmaz.
        onContinue: simulated != null
            ? () async => true
            : () async {
                final ack = await kartyService.acknowledgeUnitUnlock();
                return ack.errorCode == null;
              },
      ),
    );
    final shown = await Navigator.of(context).push(route) ?? false;
    // Kutlama ekranının çıkışı bitsin: kamera görünen patikada kaysın.
    await route.completed;
    if (!mounted) return;
    if (!shown) {
      setState(() => _arrivalUnit = null);
      return;
    }
    setState(() => _playArrival = true);
  }

  void _arrivalDone() {
    if (!mounted) return;
    setState(() {
      _arrivalUnit = null;
      _playArrival = false;
    });
  }

  /// Debug: en ileri açık ünitenin açılışını sunucuya dokunmadan oynatır
  /// (lig ekranındaki TERFİ düğmesinin karşılığı).
  void _simulateUnlock(KartyPathData data) {
    for (final unit in data.units.reversed) {
      if (unit.state == KartyUnitState.locked) continue;
      final unlock = data.unlockFor(unit.number);
      if (unlock == null) continue;
      unawaited(_maybeShowUnlock(simulated: unlock));
      return;
    }
  }

  Future<void> _continue() async {
    if (_starting) return;
    _starting = true;
    try {
      final entered = await spendTicketForGame(
        context,
        onGoToReview: () =>
            unawaited(Navigator.pushNamed(context, '/kartyreview')),
        onGoToQuests: () {
          // Görevler bir sekme; yol kapanmazsa sekme değişimi altında kalır.
          Navigator.of(context).pop();
          NavbarWidget.requestedTab.value = NavbarWidget.questsTabIndex;
        },
      );
      if (!entered || !mounted) return;
      // Dönüşte didPopNext tazeler.
      await Navigator.pushNamed(context, '/kartyquiz');
    } finally {
      _starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KartyPathProvider>();
    final tickets =
        context.watch<ScoreWithLivesProvider>().scoreWithLives?.lives ?? 0;
    final response = provider.data;

    if (response == null) {
      return _PathPlaceholder(
        loading: provider.status != KartyPathStatus.error,
        onRetry: () => provider.load(),
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    final data = KartyPathData.fromResponse(response, tickets: tickets);
    final screen = KartyPathScreen(
      data: data,
      onBack: () => Navigator.of(context).maybePop(),
      onContinue: _continue,
      onRefresh: _refresh,
      arrivalUnit: _arrivalUnit,
      playArrival: _playArrival,
      onArrivalDone: _arrivalDone,
    );
    if (!kDebugMode) return screen;
    return Stack(
      children: [
        screen,
        Positioned(
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: _DebugUnlockButton(onTap: () => _simulateUnlock(data)),
        ),
      ],
    );
  }
}

/// Debug: ünite açılışını dene. Yayından önce kaldırılacak (CLAUDE.md §8).
class _DebugUnlockButton extends StatelessWidget {
  const _DebugUnlockButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Scaffold'un dışında; Material olmadan metin sarı çizgiyle çizilir.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1CB1F5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1B84B5), offset: Offset(0, 5)),
            ],
          ),
          child: const Text(
            'AÇILIŞ',
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTypography.family,
              fontSize: 15,
              fontWeight: AppTypography.action,
            ),
          ),
        ),
      ),
    );
  }
}

/// İlk yükleme ve ilk yüklemede hata. Sonraki tazelemeler ekranı
/// değiştirmez, eldeki veriyle devam eder.
class _PathPlaceholder extends StatelessWidget {
  const _PathPlaceholder({
    required this.loading,
    required this.onRetry,
    required this.onBack,
  });

  final bool loading;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  static const _bg = Color(0xFF041227);
  static const _accent = Color(0xFF1CB1F5);
  static const _accentDepth = Color(0xFF1B84B5);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          return Center(
            child: loading
                ? const CircularProgressIndicator(color: _accent)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Karty Yolu yüklenemedi.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 28 * scale,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                      SizedBox(height: 32 * scale),
                      DepthPressableButton(
                        text: 'TEKRAR DENE',
                        width: 420 * scale,
                        height: 96 * scale,
                        radius: 26 * scale,
                        shadowOffset: 10 * scale,
                        backgroundColor: _accent,
                        shadowColor: _accentDepth,
                        fontSize: 28 * scale,
                        onPressed: onRetry,
                      ),
                      SizedBox(height: 24 * scale),
                      TextButton(
                        onPressed: onBack,
                        child: Text(
                          'Geri dön',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 26 * scale,
                            fontWeight: AppTypography.action,
                            fontFamily: AppTypography.family,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
