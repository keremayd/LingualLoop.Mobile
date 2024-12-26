import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final String img;
  final String clickedImg; // İkinci ikon
  final Color backgroundColor;
  final Color iconColor;

  const CustomIconButton({
    Key? key,
    required this.img,
    required this.clickedImg, // İkinci ikon parametresi
    required this.backgroundColor,
    required this.iconColor,
  }) : super(key: key);

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
    setState(() {
      currentIcon = currentIcon == widget.img ? widget.clickedImg : widget.img;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: _toggleIcon, // İkon değişimini tetikler
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.grey.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/icons/${currentIcon}.png',
              height: 26, // 49
            ),
          ),
        ),
      ),
    );
  }
}
