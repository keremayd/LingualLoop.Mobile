import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
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

  // Renkler §2.2'ye çekildi. Eskiden ekranın kendi paleti vardı ve
  // uygulamanın hiçbir yerinde karşılığı yoktu: zemin `#00142E`, giriş
  // kutuları `#29ABE2` parlak mavi dolgu + `#1179AE` kontur. Ekranın en
  // büyük iki yüzeyi palet dışı olduğu için ekran uygulamaya ait
  // hissettirmiyordu.
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

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
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
                    top: 300 * scale,
                    child: _LoginInput(
                      controller: _usernameController,
                      hint: 'E-posta',
                      keyboardType: TextInputType.emailAddress,
                      width: 686 * scale,
                      height: 112 * scale,
                      radius: 26 * scale,
                      borderWidth: 3.5 * scale,
                      // Form sıkılaştırıldı. Kutular 83pt yüksek, 26pt
                      // yuvarlak ve 4pt konturluydu — tipik form ölçüsü
                      // 48–56pt / r12–16 / 1–2pt. O geometri "çocuk
                      // uygulaması" hissi veriyordu ve asıl sebep metin
                      // değil kutuydu.
                      //
                      // Oyuncaklık depth-press butonda yaşamalı (§2.4).
                      // Form da aynı ölçüde şişince aradaki hiyerarşi kayboluyor.
                      fontSize: 30 * scale,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Positioned(
                    left: 32 * scale,
                    top: 430 * scale,
                    child: _LoginInput(
                      controller: _passwordController,
                      hint: 'Şifre',
                      width: 686 * scale,
                      height: 112 * scale,
                      radius: 26 * scale,
                      borderWidth: 3.5 * scale,
                      // Form sıkılaştırıldı. Kutular 83pt yüksek, 26pt
                      // yuvarlak ve 4pt konturluydu — tipik form ölçüsü
                      // 48–56pt / r12–16 / 1–2pt. O geometri "çocuk
                      // uygulaması" hissi veriyordu ve asıl sebep metin
                      // değil kutuydu.
                      //
                      // Oyuncaklık depth-press butonda yaşamalı (§2.4).
                      // Form da aynı ölçüde şişince aradaki hiyerarşi kayboluyor.
                      fontSize: 30 * scale,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  Positioned(
                    left: 48 * scale,
                    top: 620 * scale,
                    child: _PrimaryLoginButton(
                      width: 654 * scale,
                      height: 96 * scale,
                      radius: 26 * scale,
                      shadowOffset: 10 * scale,
                      fontSize: 28 * scale,
                      onPressed: () =>
                          _login(context, LoginMethod.usernamePassword),
                    ),
                  ),
                  Positioned(
                    top: 770 * scale,
                    left: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      // Büyük harf + gri, bölüm başlığı gibi okunuyordu.
                      // Accent renk ve normal yazım onu tıklanabilir bir
                      // bağlantıya çeviriyor.
                      child: Text(
                        "Parolamı unuttum",
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 29 * scale,
                          fontWeight: AppTypography.action,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                    ),
                  ),
                  // Çıplak bir çizgi neyi ayırdığını söylemiyordu; ortasına
                  // "veya" gelince alttaki sosyal girişler bir **alternatif**
                  // olarak okunuyor.
                  Positioned(
                    left: 121 * scale,
                    top: 900 * scale,
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
                    left: 226 * scale,
                    top: 990 * scale,
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
                    top: 990 * scale,
                    child: _SocialButton(
                      assetPath: 'assets/icons/apple-logo.png',
                      size: 120 * scale,
                      radius: 34 * scale,
                      iconSize: 62 * scale,
                      onTap: () => _login(context, LoginMethod.apple),
                    ),
                  ),
                  // Karşılıklı yönlendirme. Kayıt ekranında "Hesabın var mı?
                  // Giriş yap" vardı ama dönüşü yoktu; hesabı olmayan
                  // kullanıcı geri tuşuna basmak zorunda kalıyordu.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 1460 * scale,
                    child: Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        text: 'Hesabın yok mu? ',
                        style: TextStyle(
                          fontSize: 30 * scale,
                          fontWeight: AppTypography.body,
                          color: _mutedColor,
                          fontFamily: AppTypography.family,
                        ),
                        children: [
                          TextSpan(
                            text: 'Kayıt ol',
                            style: TextStyle(
                              fontSize: 30 * scale,
                              fontWeight: AppTypography.action,
                              color: _accentColor,
                              fontFamily: AppTypography.family,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/signup');
                              },
                          ),
                        ],
                      ),
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
    required this.hint,
    required this.width,
    required this.height,
    required this.radius,
    required this.borderWidth,
    required this.fontSize,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
  });

  final TextEditingController controller;

  /// **Kullanılabilirlik düzeltmesi.** İki kutu da boş ve özdeşti; hangisinin
  /// e-posta hangisinin şifre olduğu ancak dokununca anlaşılıyordu.
  final String hint;

  final TextInputType? keyboardType;
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
            fontWeight: AppTypography.body,
            fontFamily: AppTypography.family,
          ),
          keyboardType: keyboardType,
          cursorColor: _LoginScreenState._accentColor,
          decoration: InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: _LoginScreenState._mutedColor,
              fontSize: fontSize,
              fontWeight: AppTypography.body,
              fontFamily: AppTypography.family,
            ),
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

class _PrimaryLoginButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DepthPressableButton(
      text: 'Giriş yap',
      width: width,
      height: height,
      radius: radius,
      shadowOffset: shadowOffset,
      backgroundColor: _LoginScreenState._buttonColor,
      shadowColor: _LoginScreenState._buttonShadowColor,
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
        backgroundColor: _LoginScreenState._socialBackground,
        shadowColor: const Color(0xFF0B2143),
        fontSize: 0,
        onPressed: onTap,
        child: Image.asset(assetPath,
            width: iconSize, height: iconSize, fit: BoxFit.contain),
      );
}
