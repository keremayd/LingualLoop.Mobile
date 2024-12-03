import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart'; // Provider'ı ekliyoruz


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    //final olacak bunlar var değil
    var username = _usernameController.text;
    var password = _passwordController.text;

    //düzeltilecek
    username = "string";
    password = "string123";
    final authService = Provider.of<AuthService>(context, listen: false);

    var response = await authService.login(username, password, context);
    if (response.errorCode == null)
      Navigator.pushReplacementNamed(context, '/home');
    else
      print('Login failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Giriş yap',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Text(
              'Bilgilerinizi girin, öğrenmeye başlayın!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF8E9E9), width: 1.0), // Varsayılan border rengi
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF77968), width: 2.0), // Odaklanıldığında border rengi
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  labelText: 'Email')),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))), labelText: 'Şifre'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Oval kenarlar
                  ),
                  backgroundColor: Color(0xFFF66955),
                  minimumSize: Size(double.infinity, 58), // Yüksekliği input alanlarına eşitle
                ),
                onPressed: () => _login(context),
                child: Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
