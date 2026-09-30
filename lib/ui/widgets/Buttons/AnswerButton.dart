import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';
import 'depth_pressable_button.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.text,
    required this.buttonDisabledColor,
    required this.textColor,
    required this.onPressed,
  });

  final String text;
  final Color textColor;
  final Color buttonDisabledColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          return DepthPressableButton(
            width: constraints.maxWidth,
            height: MediaQuery.sizeOf(context).height * .085,
            radius: 14,
            shadowOffset: 6,
            backgroundColor: onPressed == null
                ? buttonDisabledColor
                : const Color(0xFFF9FBFF),
            shadowColor: const Color(0xFF5F5CF0),
            fontSize: 20,
            enabled: onPressed != null,
            onPressed: () => onPressed?.call(),
            child: Text(text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: AppTypography.action)),
          );
        }),
      );
}
