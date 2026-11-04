import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/flows/ticketed_game_flow.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:provider/provider.dart';

/// `/kartypath` rotası: Karty Yolu'nun verisini yükler ve tazeler, DEVAM'da
/// bileti harcayıp oyunu açar. Görünüş [KartyPathScreen]'de.
///
/// Veri dört yoldan tazelenir (§3.1): açılış, oyundan dönüş (`didPopNext`),
/// uygulamaya dönüş ve aşağı çekme. Ağ hatası ekranı bozmaz; eldeki son
/// veriyle devam edilir.
class KartyPathPage extends StatefulWidget {
  const KartyPathPage({super.key});

  @override
  State<KartyPathPage> createState() => _KartyPathPageState();
}

class _KartyPathPageState extends State<KartyPathPage>
    with WidgetsBindingObserver, RouteAware {
  ModalRoute<void>? _subscribedRoute;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<KartyPathProvider>();
      unawaited(provider.load(silent: provider.data != null));
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

    return KartyPathScreen(
      data: KartyPathData.fromResponse(response, tickets: tickets),
      onBack: () => Navigator.of(context).maybePop(),
      onContinue: _continue,
      onRefresh: _refresh,
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
