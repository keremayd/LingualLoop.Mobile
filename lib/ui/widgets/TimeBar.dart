import 'dart:async';
import 'package:flutter/material.dart';

class TimeBar extends StatefulWidget {
  final ValueNotifier<int> duration;
  final ValueNotifier<int> onReset; // Reset tetikleyicisi
  final ValueNotifier<bool> isFinished;
  ValueNotifier<bool>? isPaused; // Timer'ın durma/başlama durumu

  TimeBar({
    Key? key,
    required this.duration,
    required this.onReset,
    required this.isFinished,
    this.isPaused,
  }) : super(key: key);

  @override
  _TimeBarState createState() => _TimeBarState();
}

class _TimeBarState extends State<TimeBar> {
  double progress = 0.0;
  Timer? timer;
  double elapsedTime = 0.0; // Geçen süreyi saklamak için bir değişken

  @override
  void initState() {
    super.initState();
    startTimer();
    widget.onReset.addListener(_resetProgress);
    widget.isPaused?.addListener(_onPauseChanged);
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: widget.duration.value * 10), (Timer t) {
      setState(() {
        progress += 0.01;
        elapsedTime += 0.01; // Geçen süreyi artır
        if (progress >= 1.0) {
          timer?.cancel();
          widget.isFinished.value = true;
        }
      });
    });
  }

  void _pauseTimer() {
    if (timer != null && widget.isPaused!.value) {
      timer?.cancel();
    }
  }

  void _resumeTimer() {
    if (progress < 1.0) {
      startTimer();
    }
  }

  void _onPauseChanged() {
    if (widget.isPaused!.value) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  void _resetProgress() {
    setState(() {
      progress = 0.0;
      elapsedTime = 0.0; // Reset sırasında süreyi sıfırla
      timer?.cancel();
      startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.onReset.removeListener(_resetProgress);
    widget.isPaused?.removeListener(_onPauseChanged);
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
