import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/ErrorHandler.dart';
import '../../Enums/LoginMethod.dart';
import '../../services/AuthenticationService.dart';
import 'package:provider/provider.dart';

import '../widgets/CustomAppBar.dart';
import '../widgets/CustomIconButton.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login(BuildContext context, LoginMethod method) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    switch (method) {
      case LoginMethod.usernamePassword:
        final username = "string";
        final password = "string123";

        final response = await authService.login(username, password, context);

        if (response.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ErrorHandler.showError("Giriş başarısız: ${response.errorCode}");
        }
        break;

      case LoginMethod.google:
        final response = await authService.signInWithGoogle(context);
        if (response.errorCode == null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ErrorHandler.showError("Giriş başarısız: ${response.errorCode}");
        }
        break;

      case LoginMethod.apple:
        // TODO: Handle this case.
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 50),
              child: CustomAppBar(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF7875FC),
                          size: 35,
                        ),
                      ),
                    ),
                    Text(
                      "Bilgilerini gir",
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              children: [
                SizedBox(
                  height: 65, // istediğin yükseklik
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF7875FC),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5F5CF0),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5F5CF0),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Kullanıcı adı',
                      hintStyle: TextStyle(
                        color: Colors.white,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    ),
                  ),
                ),

                SizedBox(height: 7),
                SizedBox(
                  height: 65, // istediğin yükseklik
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF7875FC),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5F5CF0),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5F5CF0),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Parola',
                      hintStyle: TextStyle(
                        color: Colors.white,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    ),
                  ),
                ),

                SizedBox(height: 23),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF7875FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border(
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
                        backgroundColor: Color(0xFF7875FC),
                        minimumSize: Size(double.infinity, 65), // Yüksekliği input alanlarına eşitle
                      ),
                      onPressed: () => _login(context, LoginMethod.usernamePassword),
                      child: Text(
                          'GİRİŞ YAP',
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w500,
                              color: Colors.white
                          )
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 19),
                Text(
                    'PAROLAMI UNUTTUM',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF949494)
                    )
                ),

                SizedBox(height: 19),
                Padding(
                  padding: const EdgeInsets.only(left: 35, right: 35),
                  child: Container(
                    height: 4, // Kalınlık
                    width: double.infinity, // Genişlik (isteğe göre)
                    decoration: BoxDecoration(
                      color: Color(0xFF5F5CF0), // Çizgi rengi
                      borderRadius: BorderRadius.circular(5), // Kenarları uvarlat
                    ),
                  ),
                ),

                SizedBox(height: 23),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconButton(
                      img: 'google-logo',
                      backgroundColor: Color(0xFFD9D9D9),
                      buttonSize: 28,
                      padding: 13,
                      ontap: () => _login(context, LoginMethod.google),
                    ),
                    SizedBox(width: 20),
                    CustomIconButton(
                      img: 'apple-logo',
                      backgroundColor: Color(0xFFD9D9D9),
                      buttonSize: 28,
                      padding: 13,
                      ontap: () async {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 30),
          Expanded(
            child: Container(
              width: double.infinity, // Genişliği tam yap
              alignment: Alignment.bottomLeft, // İçeriği sol alta hizala
              child: Image.asset(
                'assets/images/otta_login.png',
                fit: BoxFit.fitWidth, // Genişliği kapla
                alignment: Alignment.bottomLeft, // Görselin içeriğini de sola yasla
              ),
            ),
          ),

        ],
      )
    );
  }
}
