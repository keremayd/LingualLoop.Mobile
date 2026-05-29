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

  static List<Widget> _pages = [
    HomeScreen(),
    Center(child: Text('Arama', style: TextStyle(fontSize: 24))),
    Center(child: Text('Liderlik', style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF041227),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(23),
            topRight: Radius.circular(23),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(customIconPath: 'assets/icons/home.png', index: 0, label: 'Home'),
              _buildNavItem(icon: Icons.leaderboard_rounded, index: 2, label: 'Leaderboard'),
              _buildNavItem(icon: Icons.leaderboard_rounded, index: 4, label: 'Leaderboard'),
              _buildNavItem(customIconPath: 'assets/icons/profile.png', index: 3, label: 'Profile'),
            ],
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
