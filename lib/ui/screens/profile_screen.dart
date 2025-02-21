import 'package:flutter/material.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import '../../services/AuthenticationService.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  late UserProvider userProvider;


  Future<void> _logout(BuildContext context) async {
    userProvider.clearUser();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);

    print('The user is logout');
  }

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Oval kenarlar
            ),
            backgroundColor:  Color(0xFF7875FC),
            minimumSize: Size(double.infinity, 58), // Yüksekliği input alanlarına eşitle
          ),
          onPressed: () => _logout(context),
          child: Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white)),
        ),
      ),
    );
  }
}
