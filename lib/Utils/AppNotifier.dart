import 'package:flutter/material.dart';
import '../main.dart'; // navigatorKey için

class AppNotifier {
  static void showError(String message, {Color? color}) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color ?? Colors.red.shade400,
          content: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
  }
}
