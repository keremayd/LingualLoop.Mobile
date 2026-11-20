import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';

enum AuthSocialProvider { google, apple }

/// Apple ile giriş yalnız iOS'ta: Android'de Apple'ın web akışı ve ayrı
/// sunucu ayarı gerekiyor, App Store şartı da iOS için.
bool get appleSignInShown => defaultTargetPlatform == TargetPlatform.iOS;

/// Google Cloud'daki iOS OAuth istemcisinin kimliği. iOS'ta Google ile giriş
/// bu kimlikle çalışır; Info.plist'e de tersine çevrilmiş kimlik URL şeması
/// olarak eklenmeli. Boşken iOS'ta Google düğmesi gösterilmez: yarım kalmış
/// bir giriş yolu App Store incelemesinde takılır.
const kGoogleIosClientId = '';

bool get googleSignInShown =>
    defaultTargetPlatform != TargetPlatform.iOS || kGoogleIosClientId.isNotEmpty;

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
    final apple = provider == AuthSocialProvider.apple;
    final assetPath =
        apple ? 'assets/icons/apple-logo.png' : 'assets/icons/google-logo.png';

    return Semantics(
      label: label,
      child: DepthPressableButton(
        width: size,
        height: size,
        radius: radius,
        shadowOffset: 0,
        // Apple'ın kuralı: Apple ile giriş düğmesi siyah zeminde beyaz logo
        // (ya da tersi). Palet dışı; kullanıcı onayıyla (21 Kas 2026).
        backgroundColor:
            apple ? const Color(0xFF000000) : const Color(0xFF163258),
        shadowColor: apple ? const Color(0xFF000000) : const Color(0xFF0B2143),
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
                color: apple ? const Color(0xFFFFFFFF) : null,
              ),
      ),
    );
  }
}
