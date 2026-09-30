import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/models/Requests/SignUpRequest.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
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

  // Renkler §2.2'ye çekildi — giriş ekranıyla aynı revizyon. Ekranın kendi
  // paleti vardı ve uygulamanın hiçbir yerinde karşılığı yoktu.
  static const _backgroundColor = Color(0xFF041227);
  static const _titleColor = Color(0xFFE9EEF5);
  static const _mutedColor = Color(0xFF8FA0B5);
  static const _accentColor = Color(0xFF1CB1F5);
  static const _inputFillColor = Color(0xFF0C2244);
  static const _inputBorderColor = Color(0xFF163258);
  static const _buttonColor = Color(0xFF98DE25);
  static const _buttonShadowColor = Color(0xFF6EA51C);
  static const _dividerColor = Color(0xFF0B2143);
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

  Widget _dividerLine(double scale) => Container(
        height: 5 * scale,
        decoration: BoxDecoration(
          color: _dividerColor,
          borderRadius: BorderRadius.circular(4 * scale),
        ),
      );

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
                      top: 300 * scale,
                      child: _SignUpInput(
                        controller: _firstNameController,
                        hint: "İsim",
                        width: 335 * scale,
                        height: 112 * scale,
                        radius: 26 * scale,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(26 * scale),
                          bottomLeft: Radius.circular(26 * scale),
                          topRight: Radius.circular(8 * scale),
                          bottomRight: Radius.circular(8 * scale),
                        ),
                        borderWidth: 3.5 * scale,
                        fontSize: 30 * scale,
                        hasError: _errors['firstName'] != null,
                        keyboardType: TextInputType.name,
                        onChanged: (_) =>
                            setState(() => _errors['firstName'] = null),
                      ),
                    ),
                    Positioned(
                      left: 382 * scale,
                      top: 300 * scale,
                      child: _SignUpInput(
                        controller: _lastNameController,
                        hint: "Soyisim",
                        width: 336 * scale,
                        height: 112 * scale,
                        radius: 26 * scale,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8 * scale),
                          bottomLeft: Radius.circular(8 * scale),
                          topRight: Radius.circular(26 * scale),
                          bottomRight: Radius.circular(26 * scale),
                        ),
                        borderWidth: 3.5 * scale,
                        fontSize: 30 * scale,
                        hasError: _errors['lastName'] != null,
                        keyboardType: TextInputType.name,
                        onChanged: (_) =>
                            setState(() => _errors['lastName'] = null),
                      ),
                    ),
                    Positioned(
                      left: 32 * scale,
                      top: 430 * scale,
                      child: _SignUpInput(
                        controller: _emailController,
                        hint: "E-posta",
                        width: 686 * scale,
                        height: 112 * scale,
                        radius: 26 * scale,
                        borderWidth: 3.5 * scale,
                        fontSize: 30 * scale,
                        hasError: _errors['email'] != null,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) =>
                            setState(() => _errors['email'] = null),
                      ),
                    ),
                    Positioned(
                      left: 32 * scale,
                      top: 560 * scale,
                      child: _SignUpInput(
                        controller: _passwordController,
                        hint: "Şifre",
                        width: 686 * scale,
                        height: 112 * scale,
                        radius: 26 * scale,
                        borderWidth: 3.5 * scale,
                        fontSize: 30 * scale,
                        hasError: _errors['password'] != null,
                        obscureText: true,
                        onChanged: (_) =>
                            setState(() => _errors['password'] = null),
                      ),
                    ),
                    if (errorMessage != null)
                      Positioned(
                        left: 40 * scale,
                        top: 686 * scale,
                        child: _FormWarning(
                          message: errorMessage,
                          width: 670 * scale,
                          height: 58 * scale,
                          radius: 20 * scale,
                          fontSize: 22 * scale,
                        ),
                      ),
                    Positioned(
                      left: 48 * scale,
                      top: 706 * scale + errorOffset,
                      child: _PrimarySignUpButton(
                        width: 654 * scale,
                        height: 96 * scale,
                        radius: 26 * scale,
                        shadowOffset: 10 * scale,
                        fontSize: 28 * scale,
                        onPressed: () => _signUp(context),
                      ),
                    ),
                    // Çıplak çizgi neyi ayırdığını söylemiyordu; "veya"
                    // gelince alttaki sosyal girişler alternatif olarak
                    // okunuyor.
                    Positioned(
                      left: 106 * scale,
                      top: 940 * scale + errorOffset,
                      child: SizedBox(
                        width: 508 * scale,
                        child: Row(
                          children: [
                            Expanded(child: _dividerLine(scale)),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 24 * scale),
                              child: Text(
                                'veya',
                                style: TextStyle(
                                  color: _mutedColor,
                                  fontSize: 26 * scale,
                                  fontWeight: AppTypography.caption,
                                  fontFamily: AppTypography.family,
                                ),
                              ),
                            ),
                            Expanded(child: _dividerLine(scale)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 211 * scale,
                      top: 1030 * scale + errorOffset,
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
                      top: 1030 * scale + errorOffset,
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
                      top: 1460 * scale,
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          text: 'Hesabın var mı? ',
                          style: TextStyle(
                            fontSize: 30 * scale,
                            fontWeight: AppTypography.body,
                            color: _mutedColor,
                            fontFamily: AppTypography.family,
                          ),
                          children: [
                            TextSpan(
                              // Altı çizili gri yerine accent mavi: cümlenin
                              // tıklanabilir kısmı renkle ayrılıyor, "Parolamı
                              // unuttum" ile aynı dil.
                              text: 'Giriş yap',
                              style: TextStyle(
                                fontSize: 30 * scale,
                                fontWeight: AppTypography.action,
                                color: _accentColor,
                                fontFamily: AppTypography.family,
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
                fontWeight: AppTypography.body,
                fontFamily: AppTypography.family,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                // Beyazdı — yani ipucu ile girilen değer aynı renkteydi ve
                // kutunun dolu mu boş mu olduğu anlaşılmıyordu.
                hintStyle: TextStyle(
                  color: _SignUpScreenState._mutedColor,
                  fontSize: fontSize,
                  fontWeight: AppTypography.body,
                  fontFamily: AppTypography.family,
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
                fontWeight: AppTypography.label,
                fontFamily: AppTypography.family,
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
                fontWeight: AppTypography.caption,
                fontFamily: AppTypography.family,
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
              fontWeight: AppTypography.heading,
              fontFamily: AppTypography.displayFamily,
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

class _PrimarySignUpButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DepthPressableButton(
      text: 'Kayıt ol',
      width: width,
      height: height,
      radius: radius,
      shadowOffset: shadowOffset,
      backgroundColor: _SignUpScreenState._buttonColor,
      shadowColor: _SignUpScreenState._buttonShadowColor,
      fontSize: fontSize,
      onPressed: onPressed,
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
  Widget build(BuildContext context) => DepthPressableButton(
        width: size,
        height: size,
        radius: radius,
        shadowOffset: 0,
        backgroundColor: _SignUpScreenState._socialBackground,
        shadowColor: const Color(0xFF0B2143),
        fontSize: 0,
        onPressed: onTap,
        child: Image.asset(assetPath,
            width: iconSize, height: iconSize, fit: BoxFit.contain),
      );
}
