import 'package:flutter/material.dart';
import '../../services/AuthenticationService.dart';
import 'package:provider/provider.dart';

import '../widgets/CustomAppBar.dart';


class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Color(0xFF7875FC),
                minimumSize: Size(double.infinity, 65), // Yüksekliği input alanlarına eşitle
              ),
              onPressed: () => {
                Navigator.pushNamed(context, '/login')
              },
              child: Text(
                  'GİRİŞ YAP',
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                      color: Colors.white
                  )
              ),
            ),
          ]
        ),
      ),
    );
  }
}
