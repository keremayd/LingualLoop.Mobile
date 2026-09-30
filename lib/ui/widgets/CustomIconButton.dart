import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final String img;
  final String? clickedImg; // İkinci ikon
  final Color backgroundColor;
  final Color? iconColor;
  final Function? ontap;
  final double? buttonSize;
  final double? padding;

  const CustomIconButton(
      {Key? key,
      required this.img,
      this.clickedImg, // İkinci ikon parametresi
      required this.backgroundColor,
      this.iconColor,
      this.ontap,
      this.buttonSize,
      this.padding})
      : super(key: key);

  @override
  _CustomIconButtonState createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> {
  late String currentIcon; // Şu an gösterilen ikon

  @override
  void initState() {
    super.initState();
    currentIcon = widget.img; // İlk olarak varsayılan ikonu göster
  }

  void _toggleIcon() {
    if (widget.clickedImg == null) return;

    setState(() {
      currentIcon = currentIcon == widget.img ? widget.clickedImg! : widget.img;
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.buttonSize ?? 26;
    final size = iconSize + 2 * (widget.padding ?? 10);
    return DepthPressableButton(
      width: size,
      height: size,
      radius: 14,
      shadowOffset: 0,
      backgroundColor: widget.backgroundColor,
      shadowColor: widget.backgroundColor.computeLuminance() > .5
          ? const Color(0xFFBDC5D0)
          : const Color(0xFF0B2143),
      fontSize: 0,
      enabled: widget.ontap != null,
      onPressed: () {
        widget.ontap?.call();
        _toggleIcon();
      },
      child: Image.asset('assets/icons/$currentIcon.png',
          height: iconSize, color: widget.iconColor),
    );
  }
}
