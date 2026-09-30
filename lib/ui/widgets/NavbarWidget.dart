import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/league_screen.dart';
import 'package:lingualloop/ui/screens/profile_screen.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:lingualloop/ui/widgets/Popups/streak_at_risk_popup.dart';
import 'package:provider/provider.dart';

import '../../providers/UserProvider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class NavbarWidget extends StatefulWidget {
  /// Sekmeyi dışarıdan değiştirmek için tek kanal.
  ///
  /// Bilet bitti penceresi kullanıcıyı Görevler sekmesine gönderiyor; sekme
  /// durumu navbar'ın özel state'inde tutulduğu için başka türlü erişilemiyor.
  static final ValueNotifier<int> requestedTab = ValueNotifier<int>(0);

  /// Sekme indeksleri (`_pages` sırasına bağlı).
  static const questsTabIndex = 1;
  static const leagueTabIndex = 2;
  static const profileTabIndex = 3;

  @override
  _NavbarWidgetState createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  static const _backgroundColor = Color(0xFF041227);
  static const _navCurveColor = Color(0xFF0B2143);

  static List<Widget> _pages = [
    HomeScreen(),
    QuestsScreen(),
    LeagueScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NavbarWidget.requestedTab.addListener(_applyRequestedTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordDailyActivity();
    });
  }

  void _applyRequestedTab() {
    final index = NavbarWidget.requestedTab.value;
    if (!mounted || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    NavbarWidget.requestedTab.removeListener(_applyRequestedTab);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recordDailyActivity();
    }
  }

  /// Aynı anda iki karar penceresi açılmasın: `initState` ile
  /// `didChangeAppLifecycleState` arka arkaya tetiklenebiliyor.
  bool _resolvingStreak = false;

  Future<void> _recordDailyActivity() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final response = await userService.recordDailyActivity();
      final activity = response?.data;
      if (activity == null || !mounted) return;

      final statsProvider =
          Provider.of<ProfileLearningStatsProvider>(context, listen: false);
      statsProvider.applyDailyActivity(activity);

      if (!activity.streakAtRisk || _resolvingStreak) return;

      // Koruma otomatik harcanmıyor: kısa bir seri için kıymetli bir korumayı
      // yakmak istemeyen kullanıcı olur, kararı o versin. Karar verilene kadar
      // backend seriyi askıda tutuyor, yani soru her açılışta yeniden gelir.
      //
      // Kararın yazılması pencerenin **içinde** oluyor: kart sonucu kendisi
      // gösteriyor (kapanıp yeni pencere açılmıyor), o yüzden sayıları da
      // gerçek yanıttan alması gerekiyor.
      _resolvingStreak = true;
      try {
        await showStreakAtRiskPopup(
          context,
          currentStreak: activity.currentStreak,
          missedDays: activity.missedDays,
          freezeCount: activity.freezeCount,
          week: activity.week,
          onResolve: (useFreeze) async {
            final resolved = await userService.resolveStreakFreeze(useFreeze);
            final resolvedActivity = resolved?.data;
            if (resolvedActivity != null && mounted) {
              statsProvider.applyDailyActivity(resolvedActivity);
            }
            return resolvedActivity;
          },
        );
      } finally {
        _resolvingStreak = false;
      }
    } catch (_) {
      // Günlük seri akışı ana uygulama akışını asla engellememeli.
    }
  }

  void _onItemTapped(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Not: Ligler sekmesi (index 2) kendi verisini LeagueScreen.initState +
    // didPopNext + lifecycle üzerinden tazeliyor; burada ikinci bir istek
    // atmak çift fetch'e yol açıyordu.

    if (index == 3) {
      unawaited(
        Provider.of<ProfileLearningStatsProvider>(context, listen: false)
            .refreshSilently(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final designScale = MediaQuery.of(context).size.width / 750;
    final navHorizontalRadius = 60 * designScale;
    final navVerticalRadius = 39 * designScale;
    final navStrokeWidth = 8 * designScale;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(navHorizontalRadius, navVerticalRadius),
          topRight: Radius.elliptical(navHorizontalRadius, navVerticalRadius),
        ),
        child: CustomPaint(
          foregroundPainter: _NavTopCurvePainter(
            color: _navCurveColor,
            horizontalRadius: navHorizontalRadius,
            verticalRadius: navVerticalRadius,
            strokeWidth: navStrokeWidth,
          ),
          child: Container(
            color: _backgroundColor,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 26.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      customIconPath: 'assets/icons/home.png',
                      index: 0,
                      label: 'Home'),
                  _buildNavItem(
                      customIconPath: 'assets/icons/league.png',
                      index: 2,
                      label: 'Ligler'),
                  _buildNavItem(
                      customIconPath: 'assets/icons/quest.png',
                      index: 1,
                      label: 'Görevler'),
                  _buildNavItem(
                      customIconPath: 'assets/icons/profile.png',
                      index: 3,
                      label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    String? customIconPath,
    IconData? icon,
    required int index,
    required String label,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIconPath != null
              ? Image.asset(
                  customIconPath,
                  color: isSelected ? Color(0xFF00B4FB) : Color(0xFFD1D1D1),
                  height: 28,
                  width: 28,
                )
              : Icon(
                  icon,
                  color: isSelected ? Color(0xFF00B4FB) : Color(0xFFD1D1D1),
                  size: 35,
                ),
        ],
      ),
    );
  }
}

class _NavTopCurvePainter extends CustomPainter {
  const _NavTopCurvePainter({
    required this.color,
    required this.horizontalRadius,
    required this.verticalRadius,
    required this.strokeWidth,
  });

  final Color color;
  final double horizontalRadius;
  final double verticalRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final top = strokeWidth / 2;
    final path = Path()
      ..moveTo(0, verticalRadius + top)
      ..quadraticBezierTo(0, top, horizontalRadius, top)
      ..lineTo(size.width - horizontalRadius, top)
      ..quadraticBezierTo(
        size.width,
        top,
        size.width,
        verticalRadius + top,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _NavTopCurvePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.horizontalRadius != horizontalRadius ||
        oldDelegate.verticalRadius != verticalRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
