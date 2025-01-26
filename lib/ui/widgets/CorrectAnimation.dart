import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class CorrectAnimation extends StatefulWidget {
  final int numberOfParticles;
  final int duration;
  final List<Color> colors;

  CorrectAnimation({
    Key? key,
    required this.numberOfParticles,
    required this.duration,
    this.colors = const [
      Color(0xFF7ED957),
      Color(0xFF4DB4E7),
      Colors.purpleAccent,
      Color(0xFFFFD94C),
    ],
  }) : super(key: key);

  @override
  CorrectAnimationState createState() => CorrectAnimationState();
}

class CorrectAnimationState extends State<CorrectAnimation> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: widget.duration));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void play() {
    print(widget.numberOfParticles);
    _confettiController.play();
  }

  void stop() {
    print("confetti durduruldu");
    _confettiController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirectionality: BlastDirectionality.explosive,
      gravity: 0.4,
      emissionFrequency: 0.20,
      numberOfParticles: widget.numberOfParticles,
      minBlastForce: 10,
      maxBlastForce: 60,
      minimumSize: Size(12, 6),
      maximumSize: Size(18, 9),
      colors: widget.colors,
    );
  }
}
