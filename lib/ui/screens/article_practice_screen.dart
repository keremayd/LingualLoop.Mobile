import 'package:lingualloop/ui/app_typography.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/article_practice_card.dart';
import 'package:lingualloop/ui/widgets/article_practice_locked_state.dart';
import 'package:lingualloop/ui/widgets/article_target.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:provider/provider.dart';

class ArticlePracticeScreen extends StatefulWidget {
  const ArticlePracticeScreen({super.key});

  @override
  State<ArticlePracticeScreen> createState() => _ArticlePracticeScreenState();
}

class _ArticlePracticeScreenState extends State<ArticlePracticeScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF041227);
  static const _panel = Color(0xFF0B2143);
  static const _der = Color(0xFF1CB1F5);
  static const _derBase = Color(0xFF1B84B5);
  static const _die = Color(0xFFF52A2A);
  static const _dieBase = Color(0xFFAA1C1C);
  static const _das = Color(0xFFFFB000);
  static const _dasBase = Color(0xFFC97800);
  static const _success = Color(0xFF93D334);
  static const _successBase = Color(0xFF628C22);

  late final AnimationController _motionController;
  Animation<Offset> _motionOffset = const AlwaysStoppedAnimation(Offset.zero);
  Animation<double> _motionScale = const AlwaysStoppedAnimation(1);
  Animation<double> _motionOpacity = const AlwaysStoppedAnimation(1);
  Offset _dragOffset = Offset.zero;
  String? _hoveredArticle;
  String? _receivingArticle;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(vsync: this);
    Future.microtask(context.read<ArticlePracticeProvider>().loadNext);
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  String? _articleForOffset(Offset offset, double scale) {
    final horizontalThreshold = 95 * scale;
    final verticalThreshold = 120 * scale;
    if (offset.dy < -verticalThreshold && offset.dx.abs() < 150 * scale) {
      return 'das';
    }
    if (offset.dx < -horizontalThreshold) return 'die';
    if (offset.dx > horizontalThreshold) return 'der';
    return null;
  }

  Offset _targetOffset(String article, double scale) {
    return switch (article) {
      'die' => Offset(-355 * scale, 30 * scale),
      'der' => Offset(355 * scale, 30 * scale),
      _ => Offset(0, -435 * scale),
    };
  }

  void _onPanUpdate(DragUpdateDetails details, double scale) {
    final provider = context.read<ArticlePracticeProvider>();
    if (!provider.canInteract || _motionController.isAnimating) return;
    final nextOffset = _dragOffset + details.delta;
    final nextArticle = _articleForOffset(nextOffset, scale);
    if (nextArticle != null && nextArticle != _hoveredArticle) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _isDragging = true;
      _dragOffset = nextOffset;
      _hoveredArticle = nextArticle;
    });
  }

  Future<void> _onPanEnd(double scale) async {
    final selectedArticle = _hoveredArticle;
    if (selectedArticle == null) {
      await _animateBack();
      return;
    }

    final provider = context.read<ArticlePracticeProvider>();
    final userService = context.read<UserService>();
    final profileLearningStatsProvider =
        context.read<ProfileLearningStatsProvider>();
    final result = await provider.answer(selectedArticle);
    if (!mounted) return;
    if (result?.isCorrect == true) {
      final preparedNext = provider.prepareNext();
      setState(() {
        _receivingArticle = selectedArticle;
        _hoveredArticle = selectedArticle;
      });
      await _animateFlight(_targetOffset(selectedArticle, scale));
      if (!mounted) return;
      await userService.scoreWithLivesById(context);
      if (!mounted) return;
      unawaited(
        profileLearningStatsProvider.refreshFromService(userService),
      );
      final preparedResult = await preparedNext;
      if (!mounted) return;
      _resetCardMotion();
      if (!provider.applyPrepared(preparedResult)) {
        await provider.loadNext();
      }
      return;
    }

    if (result?.isAccepted == true) {
      setState(() {
        _hoveredArticle = null;
      });
      await _animateBack();
      if (!mounted) return;
      provider.retryCurrent();
      return;
    }

    await _animateBack();
  }

  Future<void> _animateFlight(Offset target) async {
    _motionController.duration = const Duration(milliseconds: 660);
    final curve = CurvedAnimation(
      parent: _motionController,
      curve: Curves.easeInBack,
    );
    final opacityCurve = CurvedAnimation(
      parent: _motionController,
      curve: Curves.easeIn,
    );
    setState(() {
      _isDragging = false;
      _motionOffset = Tween(begin: _dragOffset, end: target).animate(curve);
      _motionScale = Tween(begin: 1.0, end: 0.24).animate(curve);
      _motionOpacity = Tween(begin: 1.0, end: 0.05).animate(opacityCurve);
    });
    await _motionController.forward(from: 0);
  }

  Future<void> _animateBack() async {
    _motionController.duration = const Duration(milliseconds: 620);
    final curve = CurvedAnimation(
      parent: _motionController,
      curve: Curves.elasticOut,
    );
    setState(() {
      _isDragging = false;
      _motionOffset =
          Tween(begin: _dragOffset, end: Offset.zero).animate(curve);
      _motionScale = const AlwaysStoppedAnimation(1);
      _motionOpacity = const AlwaysStoppedAnimation(1);
    });
    await _motionController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _motionOffset = const AlwaysStoppedAnimation(Offset.zero);
      _hoveredArticle = null;
    });
    _motionController.reset();
  }

  void _resetCardMotion() {
    _motionController.reset();
    setState(() {
      _dragOffset = Offset.zero;
      _motionOffset = const AlwaysStoppedAnimation(Offset.zero);
      _motionScale = const AlwaysStoppedAnimation(1);
      _motionOpacity = const AlwaysStoppedAnimation(1);
      _hoveredArticle = null;
      _receivingArticle = null;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / 750;
            final designHeight = 1540 * scale;
            return SizedBox(
              height: math.max(designHeight, constraints.maxHeight),
              child: Consumer<ArticlePracticeProvider>(
                builder: (context, provider, child) {
                  if (provider.status == ArticlePracticeStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _success),
                    );
                  }
                  if (provider.status == ArticlePracticeStatus.complete) {
                    return _CompleteState(
                      scale: scale,
                      onClose: () => Navigator.pop(context),
                    );
                  }
                  if (provider.status == ArticlePracticeStatus.locked) {
                    return ArticlePracticeLockedState(
                      scale: scale,
                      learnedCount: provider.learnedWordCount,
                      requiredCount: provider.requiredWordCount,
                      onClose: () => Navigator.pop(context),
                      onOpenKarty: () => Navigator.pushReplacementNamed(
                        context,
                        '/kartyquiz',
                      ),
                    );
                  }
                  if (provider.status == ArticlePracticeStatus.error ||
                      provider.task == null) {
                    return _ErrorState(
                      scale: scale,
                      onClose: () => Navigator.pop(context),
                      onRetry: provider.loadNext,
                    );
                  }
                  return _buildGame(provider, scale);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGame(ArticlePracticeProvider provider, double scale) {
    final task = provider.task!;
    const deckTop = 240.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 40 * scale,
          top: 42 * scale,
          child:
              _ExitButton(scale: scale, onClose: () => Navigator.pop(context)),
        ),
        Positioned(
          left: 95 * scale,
          top: deckTop * scale,
          child: ArticlePracticeDeckBackdrop(
            scale: scale,
            nextTask: provider.nextTask,
          ),
        ),
        Positioned(
          left: 95 * scale,
          top: deckTop * scale,
          child: AnimatedBuilder(
            animation: _motionController,
            builder: (context, child) {
              final offset = _motionController.isAnimating
                  ? _motionOffset.value
                  : _dragOffset;
              return Opacity(
                opacity: _motionOpacity.value,
                child: Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: offset.dx / (1500 * scale),
                    child: Transform.scale(
                      scale: _motionScale.value,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: TweenAnimationBuilder<double>(
              key: ValueKey(task.kartyId),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - progress) * 44 * scale),
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.diagonal3Values(
                      (503 / 560) + ((57 / 560) * progress),
                      1,
                      1,
                    ),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onPanUpdate: (details) => _onPanUpdate(details, scale),
                onPanEnd: (_) => _onPanEnd(scale),
                child: ArticlePracticeCard(
                  task: task,
                  scale: scale,
                  isDragging: _isDragging,
                  highlightedArticle: _hoveredArticle,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 267 * scale,
          top: (deckTop - 57) * scale,
          child: ArticleTarget(
            article: 'das',
            color: _das,
            baseColor: _dasBase,
            scale: scale,
            isNear: _hoveredArticle == 'das',
            isReceiving: _receivingArticle == 'das',
          ),
        ),
        Positioned(
          left: 20 * scale,
          top: (deckTop + 350) * scale,
          child: ArticleTarget(
            article: 'die',
            color: _die,
            baseColor: _dieBase,
            scale: scale,
            isNear: _hoveredArticle == 'die',
            isReceiving: _receivingArticle == 'die',
          ),
        ),
        Positioned(
          right: 20 * scale,
          top: (deckTop + 350) * scale,
          child: ArticleTarget(
            article: 'der',
            color: _der,
            baseColor: _derBase,
            scale: scale,
            isNear: _hoveredArticle == 'der',
            isReceiving: _receivingArticle == 'der',
          ),
        ),
        Positioned(
          left: 85 * scale,
          right: 85 * scale,
          top: (deckTop + 1050) * scale,
          child: _FeedbackPanel(
            scale: scale,
            provider: provider,
            nounText: task.nounText,
          ),
        ),
      ],
    );
  }
}

class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.scale, required this.onClose});

  final double scale;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = math.max(44.0, 84.75 * scale);
    return Semantics(
      label: 'Oyundan çık',
      child: DepthPressableButton(
        width: size,
        height: size - 3.125 * scale,
        radius: 24 * scale,
        shadowOffset: 8 * scale,
        backgroundColor: const Color(0xFF163258),
        shadowColor: const Color(0xFF0B2143),
        fontSize: 0,
        onPressed: onClose,
        child: KartyControlMark(
          glyph: KartyControlGlyph.cross,
          size: 50.25 * scale,
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatefulWidget {
  const _FeedbackPanel({
    required this.scale,
    required this.provider,
    required this.nounText,
  });

  final double scale;
  final ArticlePracticeProvider provider;
  final String nounText;

  @override
  State<_FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<_FeedbackPanel> {
  bool _visible = false;
  bool _wrong = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _syncFeedback(notify: false);
  }

  @override
  void didUpdateWidget(covariant _FeedbackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFeedback();
  }

  void _syncFeedback({bool notify = true}) {
    final isCorrect = widget.provider.status == ArticlePracticeStatus.correct;
    final isWrong = widget.provider.status == ArticlePracticeStatus.wrong;
    final nextVisible = isCorrect || isWrong;
    final nextWrong = isWrong ? true : (isCorrect ? false : _wrong);
    final nextMessage = isCorrect
        ? '${widget.provider.answerResult?.correctArticle ?? ''} ${widget.nounText}  +1'
        : isWrong
            ? 'Tekrar dene'
            : _message;

    if (_visible == nextVisible &&
        _wrong == nextWrong &&
        _message == nextMessage) {
      return;
    }

    void apply() {
      _visible = nextVisible;
      _wrong = nextWrong;
      _message = nextMessage;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      onEnd: () {
        if (!_visible && _message.isNotEmpty) {
          setState(() {
            _message = '';
          });
        }
      },
      child: Container(
        height: 105 * widget.scale,
        decoration: BoxDecoration(
          color: _wrong
              ? _ArticlePracticeScreenState._panel
              : _ArticlePracticeScreenState._successBase,
          borderRadius: BorderRadius.circular(26 * widget.scale),
          border: Border.all(
            color: _wrong
                ? _ArticlePracticeScreenState._die
                : _ArticlePracticeScreenState._success,
            width: 4 * widget.scale,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _message,
          style: TextStyle(
            color: Colors.white,
            fontSize: 29 * widget.scale,
            fontWeight: AppTypography.label,
            fontFamily: AppTypography.family,
          ),
        ),
      ),
    );
  }
}

class _CompleteState extends StatelessWidget {
  const _CompleteState({
    required this.scale,
    required this.onClose,
  });

  final double scale;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 54 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 176 * scale,
              height: 176 * scale,
              decoration: BoxDecoration(
                color: _ArticlePracticeScreenState._panel,
                borderRadius: BorderRadius.circular(44 * scale),
                boxShadow: [
                  BoxShadow(
                    color: _ArticlePracticeScreenState._success.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 28 * scale,
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_rounded,
                color: _ArticlePracticeScreenState._success,
                size: 94 * scale,
              ),
            ),
            SizedBox(height: 28 * scale),
            Text(
              'Harika iş!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 44 * scale,
                fontWeight: AppTypography.heading,
                fontFamily: AppTypography.displayFamily,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              'Şimdilik çalışılacak artikel kartı kalmadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 25 * scale,
                fontWeight: AppTypography.body,
                fontFamily: AppTypography.family,
                height: 1.18,
              ),
            ),
            SizedBox(height: 34 * scale),
            DepthPressableButton(
              text: 'ANA MENÜYE DÖN',
              width: 580 * scale,
              height: 78 * scale,
              radius: 24 * scale,
              shadowOffset: 8 * scale,
              backgroundColor: _ArticlePracticeScreenState._success,
              shadowColor: _ArticlePracticeScreenState._successBase,
              fontSize: 25 * scale,
              fontWeight: AppTypography.action,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.scale,
    required this.onClose,
    required this.onRetry,
  });

  final double scale;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white, size: 100 * scale),
          SizedBox(height: 24 * scale),
          TextButton(onPressed: onRetry, child: const Text('TEKRAR DENE')),
          TextButton(onPressed: onClose, child: const Text('GERİ DÖN')),
        ],
      ),
    );
  }
}
