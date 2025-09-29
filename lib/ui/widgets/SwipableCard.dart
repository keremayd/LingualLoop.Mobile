import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';

class SwipableCard extends StatefulWidget {
  final Karty card;
  final Offset position;
  final double rotation;
  final ValueNotifier<bool> isTrueAnswerBlurActive;
  final ValueNotifier<bool> isFalseAnswerBlurActive;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  SwipableCard({
    Key? key,
    required this.card,
    required this.position,
    required this.rotation,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isTrueAnswerBlurActive,
    required this.isFalseAnswerBlurActive,
  }) : super(key: key);

  @override
  _SwipableCardState createState() => _SwipableCardState();
}

class _SwipableCardState extends State<SwipableCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _shrinkController;
  late Animation<double> _shrinkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addBlurListeners();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _rotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.1, end: -0.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -0.1, end: 0.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 20),
    ]).animate(_shakeController);

    _colorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.redAccent.withOpacity(0.8),
    ).animate(_colorController);

    _shrinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
    );
  }

  void _addBlurListeners() {
    widget.isTrueAnswerBlurActive.addListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.addListener(_handleFalseAnswerBlur);
  }

  void _handleTrueAnswerBlur() {
    if (widget.isTrueAnswerBlurActive.value) {
      _scaleController.forward(from: 0);
      _rotationController.forward(from: 0);
    } else {
      _scaleController.reverse(from: 1.1);
      _rotationController.reverse(from: 0);
    }
  }

  void _handleFalseAnswerBlur() {
    if (widget.isFalseAnswerBlurActive.value) {
      _shakeController.forward(from: 0);
      _colorController.forward(from: 0);
      _shrinkController.forward(from: 0);
    } else {
      _colorController.reverse(from: 1.0);
      _shrinkController.reverse(from: 0.9);
    }
  }

  @override
  void dispose() {
    widget.isTrueAnswerBlurActive.removeListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.removeListener(_handleFalseAnswerBlur);
    _scaleController.dispose();
    _rotationController.dispose();
    _shakeController.dispose();
    _colorController.dispose();
    _shrinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              widget.card.questionText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          Transform.translate(
            offset: widget.position + Offset(_shakeAnimation.value, 0),
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleController, _rotationController, _shakeController, _colorController, _shrinkController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value * _shrinkAnimation.value,
                  child: Transform.rotate(
                    angle: widget.rotation + _rotationAnimation.value,
                    child: Container(
                      width: 230,
                      height: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7ED957),
                            Color(0xFF4DB4E7),
                            Colors.purpleAccent,
                            Color(0xFFFFD94C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(
                          color: _colorAnimation.value!,
                          width: 8,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.file(
                      File(widget.card.kartyUrl),
                      fit: BoxFit.cover,
                      width: 140,
                      key: ValueKey(DateTime.now().toString()), // Unique key forces reload
                    ),

                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}