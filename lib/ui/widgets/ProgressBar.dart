import 'dart:async';
import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final int duration;
  final ValueNotifier<bool> isCountdownFinished;
  final ValueNotifier<int> onReset; // Reset tetikleyicisi

  const ProgressBar({
    Key? key,
    required this.duration,
    required this.isCountdownFinished,
    required this.onReset,
  }) : super(key: key);

  @override
  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double progress = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
    widget.onReset.addListener(_resetProgress);
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: widget.duration * 10), (Timer t) {
      setState(() {
        progress += 0.01;
        if (progress >= 1.0) {
          timer?.cancel();
          widget.isCountdownFinished.value = true;
        }
      });
    });
  }

  void _resetProgress() {
    print(widget.duration);

    if(widget.duration == 0){
      setState(() {
        progress = 0.0;
        timer?.cancel();
      });
      return;
    }

    setState(() {
      progress = 0.0;
      timer?.cancel();
      startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.onReset.removeListener(_resetProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = 180;
        return Column(
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
                    color: progress < 0.5
                        ? Colors.green
                        : (progress < 0.8 ? Colors.orange : Colors.red),
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

