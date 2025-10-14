import 'package:flutter/material.dart';

class PressableButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color shadowColor;
  final TextStyle? textStyle;

  const PressableButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 65,
    this.borderRadius = 20,
    this.backgroundColor = const Color(0xFF7875FC),
    this.shadowColor = const Color(0xFF5F5CF0),
    this.textStyle,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40), // Butonun aşağı çökme süresi
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? [ BoxShadow(color: widget.shadowColor, offset: const Offset(0, 2)) ]
              : [ BoxShadow(color: widget.shadowColor, offset: const Offset(0, 6)) ],
        ),
        child: Container(
          height: widget.height,
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
