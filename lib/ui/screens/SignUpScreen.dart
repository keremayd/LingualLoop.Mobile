import 'package:flutter/material.dart';
import 'package:lingualloop/models/Requests/SignUpRequest.dart';
import 'package:lingualloop/models/responses/AuthenticateResponse.dart';
import 'package:lingualloop/ui/widgets/Inputs/SignUpInputField.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/Utils/ErrorHandler.dart';
import '../../services/AuthenticationService.dart';
import '../widgets/CustomAppBar.dart';
import '../widgets/CustomIconButton.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
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
      newErrors['firstName'] = 'İsim gerekli';
    }
    
    if (_lastNameController.text.trim().isEmpty) {
      newErrors['lastName'] = 'Soyisim gerekli';
    }
    
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      newErrors['email'] = 'Geçersiz e-posta adresi';
    }
    
    final password = _passwordController.text;
    if (password.isEmpty) {
      newErrors['password'] = 'Parola çok kısa';
    } else if (password.length < 6) {
      newErrors['password'] = 'Parola en az 6 karakter olmalı';
    }

    setState(() {
      _errors.addAll(newErrors);
    });

    return newErrors.values.every((e) => e == null);
  }

  Future<void> _signUp(BuildContext context) async {
    if (_validateAll()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      SignUpRequest request = SignUpRequest(firstName: _firstNameController.text, lastName: _lastNameController.text, password: _passwordController.text, email: _emailController.text);
      var signUpResponse = await authService.signUp(request, context);
      
      if (signUpResponse) {
        var loginResponse = await authService.signIn(request.email, request.password, context);
        if (loginResponse.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');
          
          return;
        }
        
        ErrorHandler.showError("Kayıt oluşturuldu, giriş başarısız. Tekrar giriş yapmayı deneyin.");

        return;
      }
      
      ErrorHandler.showError("Kayıt olurken hata oluştu!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: CustomAppBar(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF7875FC),
                          size: 35,
                        ),
                      ),
                    ),
                    const Text(
                      "Profilini oluştur",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F5CF0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SignUpInputField(
                    controller: _firstNameController,
                    hint: "İsim",
                    errorText: _errors['firstName'],
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _errors['firstName'] = null),
                  ),
                  SignUpInputField(
                    controller: _lastNameController,
                    hint: "Soyisim",
                    errorText: _errors['lastName'],
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _errors['lastName'] = null),
                  ),
                  SignUpInputField(
                    controller: _emailController,
                    hint: "E-posta",
                    errorText: _errors['email'],
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _errors['email'] = null),
                  ),
                  SignUpInputField(
                    controller: _passwordController,
                    hint: "Parola",
                    errorText: _errors['password'],
                    obscureText: true,
                    onChanged: (_) => setState(() => _errors['password'] = null),
                  ),
                  const SizedBox(height: 23),

                  // ✅ Kayıt Ol Butonu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7875FC),
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        bottom: BorderSide(
                          color: Color(0xFF5F5CF0),
                          width: 4,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: const Color(0xFF7875FC),
                          minimumSize: const Size(double.infinity, 65),
                        ),
                        onPressed: () => _signUp(context),
                        child: const Text(
                          'KAYIT OL',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 19),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F5CF0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconButton(
                        img: 'google-logo',
                        backgroundColor: const Color(0xFFD9D9D9),
                        buttonSize: 28,
                        padding: 13,
                        ontap: () {},
                      ),
                      const SizedBox(width: 20),
                      CustomIconButton(
                        img: 'apple-logo',
                        backgroundColor: const Color(0xFFD9D9D9),
                        buttonSize: 28,
                        padding: 13,
                        ontap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                text: 'Hesabınız var mı? ',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF949494),
                ),
                children: [
                  TextSpan(
                    text: 'Giriş yap',
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF949494),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
          ],
        ),
      ),
    );
  }
}
