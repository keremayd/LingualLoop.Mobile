import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  AnswerButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.085,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF9FBFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // Köşe ovallik derece
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: Color(0xFF5F5CEF), fontSize: 20),
          ),
        ),
      ),
    );
  }

}
