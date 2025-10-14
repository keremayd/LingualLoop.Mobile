import 'package:flutter/material.dart';

class AnswerButton extends StatefulWidget {
  final String text;
  final Color textColor;
  final Color buttonDisabledColor;
  final VoidCallback? onPressed;

  const AnswerButton({
    super.key,
    required this.text,
    required this.buttonDisabledColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),

        onTapUp: (_) {
          if (!isDisabled) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
          }
        },
        
        onTapCancel: () => setState(() => _isPressed = false),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 40),
          transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
          height: MediaQuery.of(context).size.height * 0.085,
          decoration: BoxDecoration(
            color: isDisabled
                ? widget.buttonDisabledColor
                : const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDisabled ? [] : _isPressed
                ? [ const BoxShadow(color: Color(0xFF5F5CF0), offset: Offset(0, 2)) ]
                : [ const BoxShadow(color: Color(0xFF5F5CF0), offset: Offset(0, 6)) ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
