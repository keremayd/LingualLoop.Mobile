import 'package:flutter/material.dart';
import 'package:stelinda/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:stelinda/ui/widgets/karty_control_glyphs.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.scale,
    required this.onPressed,
  });

  final double scale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconControlButton(
      scale: scale,
      label: 'Geri',
      onPressed: onPressed,
      child: KartyControlMark(
        glyph: KartyControlGlyph.back,
        size: 50.25 * scale,
      ),
    );
  }
}
