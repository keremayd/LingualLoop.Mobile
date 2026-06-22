import 'dart:math' as math;

import 'package:flutter/material.dart';

class KartyReviewCompleteState extends StatefulWidget {
  const KartyReviewCompleteState({
    super.key,
    required this.scale,
    required this.didCompleteSession,
    required this.onClose,
  });

  final double scale;
  final bool didCompleteSession;
  final VoidCallback onClose;

  @override
  State<KartyReviewCompleteState> createState() =>
      _KartyReviewCompleteStateState();
}

class _KartyReviewCompleteStateState extends State<KartyReviewCompleteState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Stack(
      children: [
        Positioned(
          left: 40 * scale,
          top: 155 * scale,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 56 * scale,
              height: 56 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2143),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 48 * scale,
              ),
            ),
          ),
        ),
        Positioned(
          left: 54 * scale,
          right: 54 * scale,
          top: 278 * scale,
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _ClearedKartyDeck(
                    scale: scale,
                    phase: _controller.value,
                  );
                },
              ),
              SizedBox(height: 42 * scale),
              Text(
                widget.didCompleteSession
                    ? 'Rövanşı tamamladın!'
                    : 'Rövanşlar tamam!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52 * scale,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  height: 1,
                ),
              ),
              SizedBox(height: 18 * scale),
              Text(
                widget.didCompleteSession
                    ? 'Karty\'lerle yeniden karşılaştın ve öğrendiklerini güçlendirdin.'
                    : 'Şu anda rövanş için bekleyen bir Karty bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 27 * scale,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  height: 1.25,
                ),
              ),
              SizedBox(height: 30 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scale,
                  vertical: 12 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2143),
                  borderRadius: BorderRadius.circular(22 * scale),
                  border: Border.all(
                    color: const Color(0xFF93D334).withValues(alpha: 0.48),
                    width: 2 * scale,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFFFFD52F),
                      size: 27 * scale,
                    ),
                    SizedBox(width: 10 * scale),
                    Text(
                      'Bilgilerin güçlendi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23 * scale,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 46 * scale),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 410 * scale,
                  height: 82 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93D334),
                    borderRadius: BorderRadius.circular(22 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF659D22),
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ANA MENÜYE DÖN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27 * scale,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClearedKartyDeck extends StatelessWidget {
  const _ClearedKartyDeck({
    required this.scale,
    required this.phase,
  });

  final double scale;
  final double phase;

  static const _cardGradient = LinearGradient(
    colors: [
      Color(0xFF68D73D),
      Color(0xFF56BEEA),
      Color(0xFFA647F0),
      Color(0xFFFDC041),
    ],
    stops: [0.02, 0.38, 0.68, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final pulse = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    return SizedBox(
      width: 350 * scale,
      height: 405 * scale,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(-38 * scale, 14 * scale),
            child: Transform.rotate(
              angle: -0.095,
              child: _deckCard(scale, 250, 330, 0.64),
            ),
          ),
          Transform.translate(
            offset: Offset(38 * scale, 13 * scale),
            child: Transform.rotate(
              angle: 0.095,
              child: _deckCard(scale, 250, 330, 0.78),
            ),
          ),
          Container(
            width: 270 * scale,
            height: 350 * scale,
            padding: EdgeInsets.all(17 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(38 * scale),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF93D334)
                      .withValues(alpha: 0.18 + pulse * 0.16),
                  blurRadius: (20 + pulse * 18) * scale,
                  spreadRadius: pulse * 3 * scale,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 22 * scale,
                  offset: Offset(7 * scale, 14 * scale),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: _cardGradient,
                borderRadius: BorderRadius.circular(25 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 7 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Transform.scale(
                      scale: 1 + pulse * 0.04,
                      child: Container(
                        width: 138 * scale,
                        height: 138 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF659D22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 9 * scale,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF93D334)
                                  .withValues(alpha: 0.5),
                              blurRadius: 18 * scale,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 96 * scale,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18 * scale,
                    top: 18 * scale,
                    child: _bolt(scale, -0.12),
                  ),
                  Positioned(
                    right: 18 * scale,
                    bottom: 18 * scale,
                    child: _bolt(scale, 0.12),
                  ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < 5; index++)
            Positioned(
              left: (28 + index * 68) * scale,
              top: (24 + (index.isEven ? 10 : 55)) * scale,
              child: Transform.rotate(
                angle: phase * math.pi * 2 + index,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: index.isEven
                      ? const Color(0xFFFFD52F)
                      : const Color(0xFF93D334),
                  size: (18 + index % 3 * 5) * scale,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deckCard(
    double scale,
    double width,
    double height,
    double opacity,
  ) {
    return Container(
      width: width * scale,
      height: height * scale,
      padding: EdgeInsets.all(15 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(36 * scale),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _cardGradient,
          borderRadius: BorderRadius.circular(24 * scale),
        ),
      ),
    );
  }

  Widget _bolt(double scale, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(
        'assets/icons/boost-bolt.png',
        width: 48 * scale,
        height: 64 * scale,
        fit: BoxFit.contain,
      ),
    );
  }
}
