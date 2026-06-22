import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/ProfilePhoto.dart';
import 'package:provider/provider.dart';

import '../../providers/ScoreWithLivesProvider.dart';
import '../../providers/UserProvider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenScreenState createState() => _HomeScreenScreenState();
}

class _HomeScreenScreenState extends State<HomeScreen> {
  bool isLoading = true;

  static const _backgroundColor = Color(0xFF041227);
  static const _panelBorderColor = Color(0xFF0C2244);
  static const _textColor = Colors.white;
  static const _soloColor = Color(0xFF1CB1F5);
  static const _kartyColor = _soloColor;
  static const _kartyBaseColor = Color(0xFF1B84B5);
  static const _battleColor = Color(0xFFF52A2A);
  static const _battleBaseColor = Color(0xFFAA1C1C);
  static const _reviewColor = Color(0xFF0C2244);
  static const _reviewBaseColor = Color(0xFF07182F);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await _getScoreWithLives(context);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getScoreWithLives(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.scoreWithLivesById(context);
  }

  Future<void> _updateLivesAndRouter(
      BuildContext context, String routeUrl) async {
    final userService = Provider.of<UserService>(context, listen: false);

    var apiResponse = await userService.updateLivesById();
    if (apiResponse.errorCode == null) {
      Navigator.pushNamed(context, '/$routeUrl');
      await userService.scoreWithLivesById(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: _soloColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          final contentHeight = 1567 * scale;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: contentHeight > constraints.maxHeight
                  ? contentHeight
                  : constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 40 * scale,
                    top: 24 * scale,
                    child: _ProfileSummaryCard(scale: scale),
                  ),
                  Positioned(
                    left: 40 * scale,
                    top: 304 * scale,
                    child: _SectionTitle(
                      text: "Yolculuğunu Sürdür",
                      scale: scale,
                    ),
                  ),
                  Positioned(
                    left: 40 * scale,
                    top: 368 * scale,
                    child: _KartyFeatureCard(
                      scale: scale,
                      onTap: () async {
                        await _updateLivesAndRouter(context, 'kartyquiz');
                      },
                    ),
                  ),
                  Positioned(
                    left: 40 * scale,
                    top: 859 * scale,
                    child: _SectionTitle(
                      text: "Diğer modlar",
                      scale: scale,
                      fontSize: 32,
                    ),
                  ),
                  Positioned(
                    left: 40 * scale,
                    top: 917 * scale,
                    child: Row(
                      children: [
                        _ModeCard(
                          scale: scale,
                          title: "Battle",
                          childTitle: "1v1",
                          description: "Rakiplerinle 10\nsoruda kapış!",
                          color: _battleColor,
                          baseColor: _battleBaseColor,
                          imageAsset: 'assets/images/catsbattle.png',
                          imageWidth: 255,
                          imageBottom: 38,
                          imageLeft: 26,
                          onTap: () async {
                            await _updateLivesAndRouter(context, 'videoquiz');
                          },
                        ),
                        SizedBox(width: 54 * scale),
                        _ReviewMistakesCard(
                          scale: scale,
                          onTap: () {
                            Navigator.pushNamed(context, '/kartyreview');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 670 * scale,
      height: 233 * scale,
      decoration: BoxDecoration(
        color: _HomeScreenScreenState._panelBorderColor,
        borderRadius: BorderRadius.circular(26 * scale),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8 * scale,
            top: 8 * scale,
            right: 8 * scale,
            height: 166 * scale,
            child: Container(
              decoration: BoxDecoration(
                color: _HomeScreenScreenState._backgroundColor,
                borderRadius: BorderRadius.circular(20 * scale),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    ProfilePhotoWidget(
                      width: 96 * scale,
                      height: 96 * scale,
                      borderRadius: 28 * scale,
                      editable: false,
                    ),
                    SizedBox(width: 16 * scale),
                    Expanded(
                      child: Consumer<UserProvider>(
                        builder: (context, provider, child) {
                          final firstName = provider.user?.firstName ?? "";

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Merhaba, $firstName",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _HomeScreenScreenState._textColor,
                                  fontSize: 43 * scale,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: 6 * scale),
                              Text(
                                "Almanca’ya devam et!",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _HomeScreenScreenState._textColor,
                                  fontSize: 29 * scale,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                  height: 1.05,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 14 * scale),
                    Container(
                      width: 96 * scale,
                      height: 96 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2243),
                        borderRadius: BorderRadius.circular(24 * scale),
                      ),
                      alignment: Alignment.center,
                      child: _GemIcon(scale: scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 39 * scale,
            bottom: 9 * scale,
            child: Row(
              children: [
                _ScoreItem(
                  scale: scale,
                  iconAsset: 'assets/icons/score.png',
                  valueBuilder: (provider) =>
                      "${provider.scoreWithLives?.score ?? ""}",
                  iconWidth: 44,
                ),
                SizedBox(width: 19 * scale),
                _ScoreItem(
                  scale: scale,
                  iconAsset: 'assets/icons/ticket.png',
                  valueBuilder: (provider) =>
                      "${provider.scoreWithLives?.lives ?? ""}",
                  iconWidth: 58,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewMistakesCard extends StatelessWidget {
  const _ReviewMistakesCard({
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 307 * scale;
    final height = 438 * scale;
    final baseOffset = 8 * scale;
    final radius = BorderRadius.circular(28 * scale);

    return _PressableLayeredCard(
      width: width,
      height: height,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: _HomeScreenScreenState._reviewBaseColor,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: _HomeScreenScreenState._reviewColor,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 24 * scale,
              bottom: 28 * scale,
              child: Container(
                width: 259 * scale,
                height: 190 * scale,
                decoration: BoxDecoration(
                  color: _HomeScreenScreenState._backgroundColor,
                  borderRadius: BorderRadius.circular(24 * scale),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/review_history.png',
                    width: 204 * scale,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 23 * scale,
              top: 22 * scale,
              child: Text(
                "Karty\nRövanş",
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 38 * scale,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  height: 0.98,
                ),
              ),
            ),
            Positioned(
              left: 24 * scale,
              top: 112 * scale,
              width: 252 * scale,
              child: Text(
                "Karty'lerle yeniden\nkarşılaş, bilgini\ngüçlendir.",
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 25 * scale,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  height: 1.12,
                ),
              ),
            ),
            Positioned(
              right: 20 * scale,
              top: 22 * scale,
              child: Icon(
                Icons.refresh_rounded,
                color: const Color(0xFF93D334),
                size: 52 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem({
    required this.scale,
    required this.iconAsset,
    required this.valueBuilder,
    required this.iconWidth,
  });

  final double scale;
  final String iconAsset;
  final String Function(ScoreWithLivesProvider provider) valueBuilder;
  final double iconWidth;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreWithLivesProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Image.asset(
              iconAsset,
              width: iconWidth * scale,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 9 * scale),
            Text(
              valueBuilder(provider),
              style: TextStyle(
                color: _HomeScreenScreenState._textColor,
                fontSize: 27 * scale,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GemIcon extends StatelessWidget {
  const _GemIcon({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(62 * scale, 46 * scale),
      painter: _GemPainter(),
    );
  }
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outline = Path()
      ..moveTo(w * 0.17, h * 0.02)
      ..lineTo(w * 0.83, h * 0.02)
      ..lineTo(w, h * 0.34)
      ..lineTo(w * 0.50, h)
      ..lineTo(0, h * 0.34)
      ..close();

    canvas.drawPath(outline, Paint()..color = const Color(0xFFFFA629));

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.17, h * 0.02)
        ..lineTo(w * 0.38, h * 0.02)
        ..lineTo(w * 0.30, h * 0.38)
        ..lineTo(0, h * 0.34)
        ..close(),
      Paint()..color = const Color(0xFFFFC357),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.02)
        ..lineTo(w * 0.62, h * 0.02)
        ..lineTo(w * 0.70, h * 0.38)
        ..lineTo(w * 0.30, h * 0.38)
        ..close(),
      Paint()..color = const Color(0xFFFFE074),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, h * 0.02)
        ..lineTo(w * 0.83, h * 0.02)
        ..lineTo(w, h * 0.34)
        ..lineTo(w * 0.70, h * 0.38)
        ..close(),
      Paint()..color = const Color(0xFFFF8F1F),
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.34)
        ..lineTo(w * 0.30, h * 0.38)
        ..lineTo(w * 0.50, h)
        ..close(),
      Paint()..color = const Color(0xFFFF9826),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, h * 0.38)
        ..lineTo(w * 0.70, h * 0.38)
        ..lineTo(w * 0.50, h)
        ..close(),
      Paint()..color = const Color(0xFFFFB731),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.34)
        ..lineTo(w * 0.70, h * 0.38)
        ..lineTo(w * 0.50, h)
        ..close(),
      Paint()..color = const Color(0xFFFF7C16),
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
    required this.scale,
    this.fontSize = 38,
  });

  final String text;
  final double scale;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _HomeScreenScreenState._textColor,
        fontSize: fontSize * scale,
        fontWeight: FontWeight.w800,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _KartyFeatureCard extends StatelessWidget {
  const _KartyFeatureCard({
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 670 * scale;
    final height = 438 * scale;
    final baseOffset = 8 * scale;
    final radius = BorderRadius.circular(28 * scale);

    return _PressableLayeredCard(
      width: width,
      height: height,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: _HomeScreenScreenState._kartyBaseColor,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: _HomeScreenScreenState._kartyColor,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Transform.translate(
                offset: Offset(7 * scale, 13 * scale),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 12 * scale,
                    sigmaY: 12 * scale,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.28),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/karty.png',
                      width: 350 * scale,
                      height: 350 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Transform.translate(
                offset: Offset(3 * scale, 7 * scale),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 5 * scale,
                    sigmaY: 5 * scale,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/karty.png',
                      width: 350 * scale,
                      height: 350 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 44 * scale,
              width: 350 * scale,
              height: 350 * scale,
              child: Center(
                child: Image.asset(
                  'assets/images/karty.png',
                  width: 350 * scale,
                  height: 350 * scale,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: 18 * scale,
              top: 18 * scale,
              child: Image.asset(
                'assets/icons/ticket-one.png',
                width: 68 * scale,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 30 * scale,
              top: 118 * scale,
              width: 324 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Karty",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _HomeScreenScreenState._textColor,
                      fontSize: 64 * scale,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Text(
                    "Kartları kaydır,\nyeni kelimeler\nöğren!",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _HomeScreenScreenState._textColor,
                      fontSize: 31 * scale,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.scale,
    required this.title,
    required this.description,
    required this.color,
    required this.baseColor,
    required this.imageAsset,
    required this.imageWidth,
    required this.imageBottom,
    required this.imageLeft,
    required this.onTap,
    this.childTitle,
  });

  final double scale;
  final String title;
  final String? childTitle;
  final String description;
  final Color color;
  final Color baseColor;
  final String imageAsset;
  final double imageWidth;
  final double imageBottom;
  final double imageLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 307 * scale;
    final height = 438 * scale;
    final baseOffset = 8 * scale;
    final radius = BorderRadius.circular(28 * scale);

    return _PressableLayeredCard(
      width: width,
      height: height,
      shadowOffset: baseOffset,
      radius: radius,
      baseColor: baseColor,
      onPressed: onTap,
      face: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 23 * scale,
              top: 22 * scale,
              child: Text(
                title,
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 42 * scale,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  height: 0.95,
                ),
              ),
            ),
            if (childTitle != null)
              Positioned(
                left: 24 * scale,
                top: 72 * scale,
                child: Text(
                  childTitle!,
                  style: TextStyle(
                    color: _HomeScreenScreenState._textColor,
                    fontSize: 26 * scale,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    height: 1,
                  ),
                ),
              ),
            Positioned(
              right: 18 * scale,
              top: 20 * scale,
              child: Image.asset(
                'assets/icons/ticket-one.png',
                width: 66 * scale,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 24 * scale,
              top: childTitle == null ? 106 * scale : 108 * scale,
              width: 260 * scale,
              child: Text(
                description,
                style: TextStyle(
                  color: _HomeScreenScreenState._textColor,
                  fontSize: 27 * scale,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  height: 1.12,
                ),
              ),
            ),
            Positioned(
              left: imageLeft * scale,
              bottom: imageBottom * scale,
              child: Image.asset(
                imageAsset,
                width: imageWidth * scale,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableLayeredCard extends StatefulWidget {
  const _PressableLayeredCard({
    required this.width,
    required this.height,
    required this.shadowOffset,
    required this.radius,
    required this.baseColor,
    required this.face,
    required this.onPressed,
  });

  final double width;
  final double height;
  final double shadowOffset;
  final BorderRadius radius;
  final Color baseColor;
  final Widget face;
  final VoidCallback onPressed;

  @override
  State<_PressableLayeredCard> createState() => _PressableLayeredCardState();
}

class _PressableLayeredCardState extends State<_PressableLayeredCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final faceHeight = widget.height - widget.shadowOffset;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: widget.shadowOffset,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 60),
                opacity: _isPressed ? 0 : 1,
                child: Container(
                  width: widget.width,
                  height: faceHeight,
                  decoration: BoxDecoration(
                    color: widget.baseColor,
                    borderRadius: widget.radius,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              left: 0,
              top: _isPressed ? widget.shadowOffset : 0,
              child: SizedBox(
                width: widget.width,
                height: faceHeight,
                child: widget.face,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
