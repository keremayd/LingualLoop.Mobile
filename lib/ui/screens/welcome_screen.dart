import 'package:flutter/material.dart';
import '../../services/AuthenticationService.dart';
import 'package:provider/provider.dart';

import '../widgets/Buttons/PressableButton.dart';
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
            PressableButton(
              text: 'Giriş yap',
              onPressed: () => {
                Navigator.pushNamed(context, '/signin')
              }
            ),

            SizedBox(height: 20),
            
            PressableButton(
                text: 'Kayıt ol',
                onPressed: () => {
                  Navigator.pushNamed(context, '/signup')
                }
            ),
          ]
        ),
      ),
    );
  }
}
