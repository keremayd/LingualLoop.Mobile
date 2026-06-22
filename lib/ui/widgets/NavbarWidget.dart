import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/UserProvider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class NavbarWidget extends StatefulWidget {
  @override
  _NavbarWidgetState createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int _selectedIndex = 0;
  static const _backgroundColor = Color(0xFF041227);
  static const _navCurveColor = Color(0xFF0B2143);

  static List<Widget> _pages = [
    HomeScreen(),
    Center(child: Text('Arama', style: TextStyle(fontSize: 24))),
    Center(child: Text('Liderlik', style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

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
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      customIconPath: 'assets/icons/home.png',
                      index: 0,
                      label: 'Home'),
                  _buildNavItem(
                      icon: Icons.leaderboard_rounded,
                      index: 2,
                      label: 'Leaderboard'),
                  _buildNavItem(
                      icon: Icons.leaderboard_rounded,
                      index: 4,
                      label: 'Leaderboard'),
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
                  color: isSelected ? Color(0xFF5F5CF0) : Color(0xFFD1D1D1),
                  height: 24,
                  width: 24,
                )
              : Icon(
                  icon,
                  color: isSelected ? Color(0xFF5F5CF0) : Color(0xFFD1D1D1),
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
