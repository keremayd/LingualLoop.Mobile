import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color buttonDisabledColor;
  final VoidCallback? onPressed;

  AnswerButton({required this.text, required this.buttonDisabledColor, required this.onPressed, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.085,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: buttonDisabledColor,
            backgroundColor: Color(0xFFF9FBFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

