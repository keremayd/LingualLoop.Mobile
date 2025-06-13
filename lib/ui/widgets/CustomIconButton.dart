import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final String img;
  final String clickedImg; // İkinci ikon
  final Color backgroundColor;
  final Color? iconColor;
  final Function? ontap;
  final double? buttonSize;
  final double? padding;

  const CustomIconButton({
    Key? key,
    required this.img,
    required this.clickedImg, // İkinci ikon parametresi
    required this.backgroundColor,
    this.iconColor,
    this.ontap,
    this.buttonSize,
    this.padding
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
    // Butonun devre dışı olup olmadığını kontrol et
    bool isButtonDisabled = widget.ontap == null;

    return Material(
      color: widget.iconColor,
      borderRadius: BorderRadius.circular(14),
      child: AbsorbPointer(
        absorbing: isButtonDisabled, // Buton devre dışıysa, etkileşimi yutuyoruz
        child: Ink(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: isButtonDisabled
                ? null // Buton devre dışıysa tıklanamaz
                : () {
              widget.ontap!(); // Null check yapmadan doğrudan fonksiyonu çağır
              _toggleIcon(); // Önce ikon değişimini yap
            },
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.grey.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(widget.padding ?? 10),
              child: Opacity(
                opacity: isButtonDisabled ? 0.5 : 1.0, // Buton devre dışıysa opaklık %50
                child: Image.asset(
                  'assets/icons/${currentIcon}.png',
                  height: widget.buttonSize ?? 26, // 49
                  color: widget.iconColor, // Rengi gri yapıyoruz
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
