import 'package:lingualloop/ui/app_typography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/main.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_social_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:provider/provider.dart';

import '../../Enums/LoginMethod.dart';
import '../../services/AuthenticationService.dart';

enum _LoginSource { form, test, google }

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginSource? _loadingSource;
  String? _errorMessage;
  bool _emailInvalid = false;
  bool _passwordInvalid = false;

  bool get _isLoading => _loadingSource != null;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
  static const _warningColor = Color(0xFFFF4D5E);

  void _clearError() {
    if (_errorMessage == null && !_emailInvalid && !_passwordInvalid) return;
    setState(() {
      _errorMessage = null;
      _emailInvalid = false;
      _passwordInvalid = false;
    });
  }

  bool _validateCredentials() {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;
    final emailInvalid = !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    final passwordInvalid = password.isEmpty;
    if (!emailInvalid && !passwordInvalid) return true;

    setState(() {
      _emailInvalid = emailInvalid;
      _passwordInvalid = passwordInvalid;
      _errorMessage = email.isEmpty
          ? 'E-posta adresini gir.'
          : emailInvalid
              ? 'Geçerli bir e-posta adresi gir.'
              : 'Şifreni gir.';
    });
    return false;
  }

  String _failureMessage(Object error, LoginMethod method) {
    if (error is DioError) {
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 401) {
        return method == LoginMethod.usernamePassword
            ? 'E-posta veya şifre hatalı.'
            : 'Google ile giriş yapılamadı. Tekrar dene.';
      }
      if (error.type == DioErrorType.connectTimeout ||
          error.type == DioErrorType.sendTimeout ||
          error.type == DioErrorType.receiveTimeout ||
          error.type == DioErrorType.other) {
        return 'Bağlantı kurulamadı. İnternetini ve sunucuyu kontrol et.';
      }
    }
    return 'Şu anda giriş yapılamıyor. Lütfen tekrar dene.';
  }

  Future<void> _login(LoginMethod method, {bool useTestAccount = false}) async {
    if (_isLoading) return;
    if (useTestAccount && !kDebugMode) return;
    if (method == LoginMethod.apple) {
      setState(() => _errorMessage = 'Apple ile giriş henüz kullanılamıyor.');
      return;
    }
    if (method == LoginMethod.usernamePassword &&
        !useTestAccount &&
        !_validateCredentials()) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _errorMessage = null;
      _emailInvalid = false;
      _passwordInvalid = false;
      _loadingSource = method == LoginMethod.google
          ? _LoginSource.google
          : useTestAccount
              ? _LoginSource.test
              : _LoginSource.form;
    });

    try {
      final response = method == LoginMethod.google
          ? await authService.signInWithGoogle(context)
          : await authService.signIn(
              // Test hesabı yalnız debug derlemesindeki ayrı butondan gelir.
              useTestAccount
                  ? 'sefa@gmail.com'
                  : _usernameController.text.trim(),
              useTestAccount ? 'sefa123' : _passwordController.text,
              context,
            );
      if (!mounted) return;
      if (response.errorCode == null && response.data != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = method == LoginMethod.google
              ? response.errorCode == 'İşlem iptal edildi!'
                  ? 'Google ile giriş iptal edildi.'
                  : 'Google ile giriş yapılamadı. Tekrar dene.'
              : 'E-posta veya şifre hatalı.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _failureMessage(error, method));
      }
    } finally {
      if (mounted) setState(() => _loadingSource = null);
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
                      enabled: !_isLoading,
                      invalid: _emailInvalid,
                      onChanged: (_) => _clearError(),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      autofillHints: const [AutofillHints.email],
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
                      enabled: !_isLoading,
                      invalid: _passwordInvalid,
                      onChanged: (_) => _clearError(),
                      onSubmitted: (_) => _login(LoginMethod.usernamePassword),
                      autofillHints: const [AutofillHints.password],
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
                  if (_errorMessage != null || _isLoading)
                    Positioned(
                      left: 48 * scale,
                      right: 48 * scale,
                      top: 557 * scale,
                      height: 58 * scale,
                      child: Semantics(
                        liveRegion: true,
                        child: Center(
                          child: Text(
                            _errorMessage ??
                                (_loadingSource == _LoginSource.google
                                    ? 'Google ile giriş yapılıyor...'
                                    : 'Giriş yapılıyor...'),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _errorMessage == null
                                  ? _mutedColor
                                  : _warningColor,
                              fontSize: 24 * scale,
                              fontWeight: AppTypography.label,
                              fontFamily: AppTypography.family,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 32 * scale,
                    top: 620 * scale,
                    child: _PrimaryLoginButton(
                      width: 686 * scale,
                      height: 96 * scale,
                      radius: 26 * scale,
                      shadowOffset: 10 * scale,
                      fontSize: 28 * scale,
                      enabled: !_isLoading,
                      isLoading: _loadingSource == _LoginSource.form,
                      onPressed: () => _login(LoginMethod.usernamePassword),
                    ),
                  ),
                  Positioned(
                    top: 770 * scale,
                    left: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {},
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
                    child: AuthSocialButton(
                      provider: AuthSocialProvider.google,
                      label: 'Google ile giriş yap',
                      size: 120 * scale,
                      radius: 34 * scale,
                      iconSize: 62 * scale,
                      enabled: !_isLoading,
                      isLoading: _loadingSource == _LoginSource.google,
                      onPressed: () => _login(LoginMethod.google),
                    ),
                  ),
                  Positioned(
                    left: 400 * scale,
                    top: 990 * scale,
                    child: AuthSocialButton(
                      provider: AuthSocialProvider.apple,
                      label: 'Apple ile giriş yap',
                      size: 120 * scale,
                      radius: 34 * scale,
                      iconSize: 62 * scale,
                      enabled: !_isLoading,
                      onPressed: () => _login(LoginMethod.apple),
                    ),
                  ),
                  if (kDebugMode)
                    Positioned(
                      left: 143 * scale,
                      top: 1190 * scale,
                      child: DepthPressableButton(
                        width: 464 * scale,
                        height: 82 * scale,
                        radius: 24 * scale,
                        shadowOffset: 9 * scale,
                        backgroundColor: const Color(0xFF163258),
                        shadowColor: const Color(0xFF0B2143),
                        fontSize: 0,
                        enabled: !_isLoading,
                        onPressed: () => _login(LoginMethod.usernamePassword,
                            useTestAccount: true),
                        child: _loadingSource == _LoginSource.test
                            ? SizedBox(
                                width: 32 * scale,
                                height: 32 * scale,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'TEST GİRİŞİ',
                                style: TextStyle(
                                  color: _titleColor,
                                  fontSize: 27 * scale,
                                  fontWeight: AppTypography.action,
                                  fontFamily: AppTypography.family,
                                ),
                              ),
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
    required this.enabled,
    required this.invalid,
    required this.onChanged,
    required this.onSubmitted,
    required this.autofillHints,
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
  final bool enabled;
  final bool invalid;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Iterable<String> autofillHints;
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
          color: invalid
              ? _LoginScreenState._warningColor
              : _LoginScreenState._inputBorderColor,
          width: borderWidth,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 36 * width / 686),
      child: Center(
        child: TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          autocorrect: false,
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
      height: AppIconControlButton.outerHeightForScale(scale),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20 * scale,
            child: AuthBackButton(
              scale: scale,
              onPressed: () {
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

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.width,
    required this.height,
    required this.radius,
    required this.shadowOffset,
    required this.fontSize,
    required this.onPressed,
    required this.enabled,
    required this.isLoading,
  });

  final double width;
  final double height;
  final double radius;
  final double shadowOffset;
  final double fontSize;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DepthPressableButton(
      width: width,
      height: height,
      radius: radius,
      shadowOffset: shadowOffset,
      backgroundColor: _LoginScreenState._buttonColor,
      shadowColor: _LoginScreenState._buttonShadowColor,
      fontSize: fontSize,
      enabled: enabled,
      onPressed: onPressed,
      child: isLoading
          ? SizedBox(
              width: fontSize * 1.1,
              height: fontSize * 1.1,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              'Giriş yap',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: AppTypography.action,
                fontFamily: AppTypography.family,
              ),
            ),
    );
  }
}
