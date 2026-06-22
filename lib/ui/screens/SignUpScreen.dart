import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/models/Requests/SignUpRequest.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import '../../services/AuthenticationService.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final Map<String, String?> _errors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'password': null,
  };

  static const _backgroundColor = Color(0xFF00142E);
  static const _titleColor = Color(0xFFA7A7A7);
  static const _inputFillColor = Color(0xFF29ABE2);
  static const _inputBorderColor = Color(0xFF1179AE);
  static const _buttonColor = Color(0xFF98DE25);
  static const _buttonShadowColor = Color(0xFF6EA51C);
  static const _dividerColor = Color(0xFF0A2A5D);
  static const _socialBackground = Color(0xFFE9E9E9);
  static const _warningColor = Color(0xFFFF4D5E);
  static const _warningBackgroundColor = Color(0xFF102948);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateAll() {
    final Map<String, String?> newErrors = {};

    if (_firstNameController.text.trim().isEmpty) {
      newErrors['firstName'] = 'İsmini yazmalısın.';
    }

    if (_lastNameController.text.trim().isEmpty) {
      newErrors['lastName'] = 'Soyismini yazmalısın.';
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      newErrors['email'] = 'Geçerli bir email adresi yazmalısın.';
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      newErrors['password'] = 'Şifre alanını doldurmalısın.';
    } else if (password.length < 6) {
      newErrors['password'] = 'Şifren en az 6 karakter olmalı.';
    }

    setState(() {
      _errors.addAll(newErrors);
    });

    return newErrors.values.every((e) => e == null);
  }

  String? get _visibleErrorMessage {
    for (final key in ['firstName', 'lastName', 'email', 'password']) {
      final error = _errors[key];
      if (error != null) {
        return error;
      }
    }

    return null;
  }

  Future<void> _signUp(BuildContext context) async {
    if (_validateAll()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      SignUpRequest request = SignUpRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          password: _passwordController.text,
          email: _emailController.text);
      var signUpResponse = await authService.signUp(request, context);

      if (signUpResponse) {
        var loginResponse =
            await authService.signIn(request.email, request.password, context);
        if (loginResponse.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');

          return;
        }

        AppNotifier.showMessage(
            "Kayıt oluşturuldu, giriş başarısız. Tekrar giriş yapmayı deneyin.");

        return;
      }

      AppNotifier.showMessage("Kayıt olurken hata oluştu!");
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
          final errorMessage = _visibleErrorMessage;
          final errorOffset = errorMessage == null ? 0.0 : 82 * scale;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 140 * scale,
                      child: _SignUpHeader(
                        scale: scale,
                        titleColor: _titleColor,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      left: 32 * scale,
                      top: 260 * scale,
                      child: _SignUpInput(
                        controller: _firstNameController,
                        hint: "İsim",
                        width: 335 * scale,
                        height: 145 * scale,
                        radius: 42 * scale,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(46 * scale),
                          bottomLeft: Radius.circular(46 * scale),
                          topRight: Radius.circular(10 * scale),
                          bottomRight: Radius.circular(10 * scale),
                        ),
                        borderWidth: 7 * scale,
                        fontSize: 35 * scale,
                        hasError: _errors['firstName'] != null,
                        keyboardType: TextInputType.name,
                        onChanged: (_) =>
                            setState(() => _errors['firstName'] = null),
                      ),
                    ),
                    Positioned(
                      left: 382 * scale,
                      top: 260 * scale,
                      child: _SignUpInput(
                        controller: _lastNameController,
                        hint: "Soyisim",
                        width: 336 * scale,
                        height: 145 * scale,
                        radius: 42 * scale,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10 * scale),
                          bottomLeft: Radius.circular(10 * scale),
                          topRight: Radius.circular(46 * scale),
                          bottomRight: Radius.circular(46 * scale),
                        ),
                        borderWidth: 7 * scale,
                        fontSize: 35 * scale,
                        hasError: _errors['lastName'] != null,
                        keyboardType: TextInputType.name,
                        onChanged: (_) =>
                            setState(() => _errors['lastName'] = null),
                      ),
                    ),
                    Positioned(
                      left: 32 * scale,
                      top: 421 * scale,
                      child: _SignUpInput(
                        controller: _emailController,
                        hint: "Email",
                        width: 686 * scale,
                        height: 145 * scale,
                        radius: 46 * scale,
                        borderWidth: 7 * scale,
                        fontSize: 35 * scale,
                        hasError: _errors['email'] != null,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) =>
                            setState(() => _errors['email'] = null),
                      ),
                    ),
                    Positioned(
                      left: 32 * scale,
                      top: 585 * scale,
                      child: _SignUpInput(
                        controller: _passwordController,
                        hint: "Şifre",
                        width: 686 * scale,
                        height: 145 * scale,
                        radius: 46 * scale,
                        borderWidth: 7 * scale,
                        fontSize: 35 * scale,
                        hasError: _errors['password'] != null,
                        obscureText: true,
                        onChanged: (_) =>
                            setState(() => _errors['password'] = null),
                      ),
                    ),
                    if (errorMessage != null)
                      Positioned(
                        left: 40 * scale,
                        top: 746 * scale,
                        child: _FormWarning(
                          message: errorMessage,
                          width: 670 * scale,
                          height: 58 * scale,
                          radius: 20 * scale,
                          fontSize: 22 * scale,
                        ),
                      ),
                    Positioned(
                      left: 40 * scale,
                      top: 766 * scale + errorOffset,
                      child: _PrimarySignUpButton(
                        width: 670 * scale,
                        height: 130 * scale,
                        radius: 38 * scale,
                        shadowOffset: 7 * scale,
                        fontSize: 45 * scale,
                        onPressed: () => _signUp(context),
                      ),
                    ),
                    Positioned(
                      left: 106 * scale,
                      top: 996 * scale + errorOffset,
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
                      left: 211 * scale,
                      top: 1072 * scale + errorOffset,
                      child: _SocialButton(
                        assetPath: 'assets/icons/google-logo.png',
                        size: 120 * scale,
                        radius: 34 * scale,
                        iconSize: 62 * scale,
                        onTap: () {},
                      ),
                    ),
                    Positioned(
                      left: 384 * scale,
                      top: 1072 * scale + errorOffset,
                      child: _SocialButton(
                        assetPath: 'assets/icons/apple-logo.png',
                        size: 120 * scale,
                        radius: 34 * scale,
                        iconSize: 62 * scale,
                        onTap: () {},
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 1475 * scale,
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          text: 'Hesabınız var mı? ',
                          style: TextStyle(
                            fontSize: 30 * scale,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                            fontFamily: 'Inter',
                          ),
                          children: [
                            TextSpan(
                              text: 'Giriş yap',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: _titleColor,
                                decorationThickness: 2 * scale,
                                fontSize: 30 * scale,
                                fontWeight: FontWeight.w700,
                                color: _titleColor,
                                fontFamily: 'Inter',
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, "/signin");
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignUpInput extends StatelessWidget {
  const _SignUpInput({
    required this.controller,
    required this.hint,
    required this.width,
    required this.height,
    required this.radius,
    required this.borderWidth,
    required this.fontSize,
    required this.onChanged,
    this.borderRadius,
    this.hasError = false,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final double width;
  final double height;
  final double radius;
  final double borderWidth;
  final double fontSize;
  final BorderRadius? borderRadius;
  final bool hasError;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = height / 145;

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _SignUpScreenState._inputFillColor,
              borderRadius: borderRadius ?? BorderRadius.circular(radius),
              border: Border.all(
                color: hasError
                    ? _SignUpScreenState._warningColor
                    : _SignUpScreenState._inputBorderColor,
                width: borderWidth,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 56 * scale),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              onChanged: onChanged,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormWarning extends StatelessWidget {
  const _FormWarning({
    required this.message,
    required this.width,
    required this.height,
    required this.radius,
    required this.fontSize,
  });

  final String message;
  final double width;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scale = height / 58;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 22 * scale),
      decoration: BoxDecoration(
        color: _SignUpScreenState._warningBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _SignUpScreenState._warningColor,
          width: 3 * scale,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24 * scale,
            height: 24 * scale,
            decoration: const BoxDecoration(
              color: _SignUpScreenState._warningColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '!',
              style: TextStyle(
                color: _SignUpScreenState._backgroundColor,
                fontSize: 17 * scale,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _SignUpScreenState._warningColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader({
    required this.scale,
    required this.titleColor,
    required this.onBack,
  });

  final double scale;
  final Color titleColor;
  final VoidCallback onBack;

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
              onTap: onBack,
            ),
          ),
          Text(
            "Profilini oluştur",
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

class _PrimarySignUpButton extends StatefulWidget {
  const _PrimarySignUpButton({
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
  State<_PrimarySignUpButton> createState() => _PrimarySignUpButtonState();
}

class _PrimarySignUpButtonState extends State<_PrimarySignUpButton> {
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
                    color: _SignUpScreenState._buttonShadowColor,
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
                  color: _SignUpScreenState._buttonColor,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
                child: Center(
                  child: Text(
                    "KAYIT OL",
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
          color: _SignUpScreenState._socialBackground,
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
