import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/main.dart';
import 'package:provider/provider.dart';

import '../../Enums/LoginMethod.dart';
import '../../services/AuthenticationService.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _backgroundColor = Color(0xFF00142E);
  static const _titleColor = Color(0xFFA7A7A7);
  static const _inputFillColor = Color(0xFF29ABE2);
  static const _inputBorderColor = Color(0xFF1179AE);
  static const _buttonColor = Color(0xFF98DE25);
  static const _buttonShadowColor = Color(0xFF6EA51C);
  static const _dividerColor = Color(0xFF0A2A5D);
  static const _socialBackground = Color(0xFFE9E9E9);

  Future<void> _login(BuildContext context, LoginMethod method) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    switch (method) {
      case LoginMethod.usernamePassword:
        final username = "sefa@gmail.com";
        final password = "sefa123";

        final response = await authService.signIn(username, password, context);

        if (response.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          AppNotifier.showMessage("Giriş başarısız: ${response.errorCode}");
        }
        break;

      case LoginMethod.google:
        final response = await authService.signInWithGoogle(context);
        if (response.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          AppNotifier.showMessage("Giriş başarısız: ${response.errorCode}");
        }
        break;

      case LoginMethod.apple:
      // TODO: Handle this case.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          final canvasHeight = 1624 * scale;
          final height = canvasHeight > constraints.maxHeight
              ? canvasHeight
              : constraints.maxHeight;

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned(
                    left: -12 * scale,
                    top: 1168 * scale,
                    child: Image.asset(
                      'assets/images/otta_login.png',
                      width: 500 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 140 * scale,
                    child: _LoginHeader(
                      scale: scale,
                      titleColor: _titleColor,
                    ),
                  ),
                  Positioned(
                    left: 32 * scale,
                    top: 260 * scale,
                    child: _LoginInput(
                      controller: _usernameController,
                      width: 686 * scale,
                      height: 145 * scale,
                      radius: 46 * scale,
                      borderWidth: 7 * scale,
                      fontSize: 28 * scale,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Positioned(
                    left: 32 * scale,
                    top: 423 * scale,
                    child: _LoginInput(
                      controller: _passwordController,
                      width: 686 * scale,
                      height: 145 * scale,
                      radius: 46 * scale,
                      borderWidth: 7 * scale,
                      fontSize: 28 * scale,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  Positioned(
                    left: 40 * scale,
                    top: 620 * scale,
                    child: _PrimaryLoginButton(
                      width: 670 * scale,
                      height: 130 * scale,
                      radius: 38 * scale,
                      shadowOffset: 7 * scale,
                      fontSize: 44 * scale,
                      onPressed: () =>
                          _login(context, LoginMethod.usernamePassword),
                    ),
                  ),
                  Positioned(
                    top: 814 * scale,
                    left: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "PAROLAMI UNUTTUM",
                        style: TextStyle(
                          color: _titleColor,
                          fontSize: 29 * scale,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 121 * scale,
                    top: 897 * scale,
                    child: Container(
                      width: 508 * scale,
                      height: 7 * scale,
                      decoration: BoxDecoration(
                        color: _dividerColor,
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 226 * scale,
                    top: 976 * scale,
                    child: _SocialButton(
                      assetPath: 'assets/icons/google-logo.png',
                      size: 120 * scale,
                      radius: 34 * scale,
                      iconSize: 62 * scale,
                      onTap: () => _login(context, LoginMethod.google),
                    ),
                  ),
                  Positioned(
                    left: 400 * scale,
                    top: 976 * scale,
                    child: _SocialButton(
                      assetPath: 'assets/icons/apple-logo.png',
                      size: 120 * scale,
                      radius: 34 * scale,
                      iconSize: 62 * scale,
                      onTap: () => _login(context, LoginMethod.apple),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.controller,
    required this.width,
    required this.height,
    required this.radius,
    required this.borderWidth,
    required this.fontSize,
    this.obscureText = false,
    this.textInputAction,
  });

  final TextEditingController controller;
  final double width;
  final double height;
  final double radius;
  final double borderWidth;
  final double fontSize;
  final bool obscureText;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _LoginScreenState._inputFillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _LoginScreenState._inputBorderColor,
          width: borderWidth,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 36 * width / 686),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({
    required this.scale,
    required this.titleColor,
  });

  final double scale;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20 * scale,
            child: _BackArrowButton(
              scale: scale,
              color: titleColor,
              onTap: () {
                final navigator = navigatorKey.currentState;
                if (navigator == null) {
                  return;
                }

                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacementNamed('/welcome');
                }
              },
            ),
          ),
          Text(
            "Bilgilerini gir",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 45 * scale,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _BackArrowButton extends StatelessWidget {
  const _BackArrowButton({
    required this.scale,
    required this.color,
    required this.onTap,
  });

  final double scale;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(46 * scale),
        onTap: onTap,
        child: SizedBox(
          width: 92 * scale,
          height: 92 * scale,
          child: Center(
            child: CustomPaint(
              size: Size(58 * scale, 58 * scale),
              painter: _BackArrowPainter(
                color: color,
                strokeWidth: 6.6 * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.56, size.height * 0.14)
      ..lineTo(size.width * 0.16, size.height * 0.50)
      ..lineTo(size.width * 0.56, size.height * 0.86)
      ..moveTo(size.width * 0.18, size.height * 0.50)
      ..lineTo(size.width * 0.90, size.height * 0.50);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _PrimaryLoginButton extends StatefulWidget {
  const _PrimaryLoginButton({
    required this.width,
    required this.height,
    required this.radius,
    required this.shadowOffset,
    required this.fontSize,
    required this.onPressed,
  });

  final double width;
  final double height;
  final double radius;
  final double shadowOffset;
  final double fontSize;
  final VoidCallback onPressed;

  @override
  State<_PrimaryLoginButton> createState() => _PrimaryLoginButtonState();
}

class _PrimaryLoginButtonState extends State<_PrimaryLoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height + widget.shadowOffset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: widget.shadowOffset,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 60),
                opacity: _isPressed ? 0 : 1,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: _LoginScreenState._buttonShadowColor,
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              left: 0,
              top: _isPressed ? widget.shadowOffset : 0,
              width: widget.width,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: _LoginScreenState._buttonColor,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
                child: Center(
                  child: Text(
                    "GİRİŞ YAP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.assetPath,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.onTap,
  });

  final String assetPath;
  final double size;
  final double radius;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _LoginScreenState._socialBackground,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
