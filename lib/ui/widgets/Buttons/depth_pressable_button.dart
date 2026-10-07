import 'package:lingualloop/ui/app_typography.dart';
import 'app_button_style.dart';
import 'package:flutter/material.dart';

class DepthPressableButton extends StatefulWidget {
  const DepthPressableButton({
    super.key,
    this.text,
    this.child,
    required this.width,
    required this.height,
    required this.radius,
    required this.shadowOffset,
    this.roundedDepthOverride,
    required this.backgroundColor,
    required this.shadowColor,
    required this.fontSize,
    required this.onPressed,
    this.fontWeight = AppTypography.action,
    this.enabled = true,
  }) : assert(
          (text == null) != (child == null),
          'Provide exactly one of text or child.',
        );

  final String? text;
  final Widget? child;
  final double width;
  final double height;
  final double radius;
  final double shadowOffset;

  /// Ortak yuvarlak stil açıkken kullanılacak alt katman kalınlığı.
  final double? roundedDepthOverride;
  final Color backgroundColor;
  final Color shadowColor;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<DepthPressableButton> createState() => _DepthPressableButtonState();
}

class _DepthPressableButtonState extends State<DepthPressableButton> {
  bool _isPressed = false;

  @override
  void didUpdateWidget(covariant DepthPressableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _isPressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final isVisuallyPressed = _isPressed || !widget.enabled;
    final geometry = AppButtonStyle.resolve(
      width: widget.width,
      totalHeight: widget.height + widget.shadowOffset,
      legacyRadius: widget.radius,
      legacyDepth: widget.shadowOffset,
      roundedDepthOverride: widget.roundedDepthOverride,
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _isPressed = false) : null,
          onTapUp: widget.enabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed();
                }
              : null,
          child: SizedBox(
            width: widget.width,
            height: geometry.faceHeight + geometry.depth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: geometry.depth,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 60),
                    opacity: isVisuallyPressed ? 0 : 1,
                    child: Container(
                      width: widget.width,
                      height: geometry.faceHeight,
                      decoration: BoxDecoration(
                        color: widget.shadowColor,
                        borderRadius: BorderRadius.circular(geometry.radius),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  left: 0,
                  top: isVisuallyPressed ? geometry.depth : 0,
                  width: widget.width,
                  height: geometry.faceHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(geometry.radius),
                    ),
                    alignment: Alignment.center,
                    child: widget.child ??
                        Text(
                          widget.text!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.fontSize,
                            fontWeight: widget.fontWeight,
                            fontFamily: AppTypography.family,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
