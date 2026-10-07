import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

enum AuthSocialProvider { google, apple }

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.provider,
    required this.label,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final AuthSocialProvider provider;
  final String label;
  final double size;
  final double radius;
  final double iconSize;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final assetPath = provider == AuthSocialProvider.google
        ? 'assets/icons/google-logo.png'
        : 'assets/icons/apple-logo.png';

    return Semantics(
      label: label,
      child: DepthPressableButton(
        width: size,
        height: size,
        radius: radius,
        shadowOffset: 0,
        backgroundColor: const Color(0xFF163258),
        shadowColor: const Color(0xFF0B2143),
        fontSize: 0,
        enabled: enabled,
        onPressed: onPressed,
        child: isLoading
            ? SizedBox.square(
                dimension: iconSize * 0.55,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE9EEF5),
                ),
              )
            : Image.asset(
                assetPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                color: provider == AuthSocialProvider.apple
                    ? const Color(0xFFE9EEF5)
                    : null,
              ),
      ),
    );
  }
}
