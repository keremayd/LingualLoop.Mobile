import 'dart:async';
import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final int duration; // Süre (saniye cinsinden)
  final ValueNotifier<bool> isCountdownFinished; // Sürenin bitişini takip etmek için

  const ProgressBar({
    Key? key,
    required this.duration,
    required this.isCountdownFinished,
  }) : super(key: key);

  @override
  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double progress = 0.0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      setState(() {
        progress += 0.01;
        if (progress >= 1.0) {
          timer.cancel();
          widget.isCountdownFinished.value = true; // Merkezi state güncelle
        }
      });
    });
  }

  Color getProgressColor() {
    if (progress < 0.5) {
      return Colors.green;
    } else if (progress < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = 180;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: 180,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey[300],
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: maxWidth * progress,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: getProgressColor(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
