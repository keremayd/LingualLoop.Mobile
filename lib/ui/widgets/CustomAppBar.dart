import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final Widget child;

  const CustomAppBar({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical:18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent, // AppBar arka plan rengi
            borderRadius: BorderRadius.circular(20),

          ),
          child: Center(
            child: child, // Dışarıdan gönderilen içerik burada gösteriliyor
          ),
        )
    );
  }
}
