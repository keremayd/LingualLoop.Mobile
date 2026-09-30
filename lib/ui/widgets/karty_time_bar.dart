import 'dart:async';

import 'package:flutter/material.dart';

class KartyTimeBar extends StatefulWidget {
  const KartyTimeBar({
    super.key,
    required this.width,
    required this.height,
    required this.duration,
    required this.onReset,
    required this.isFinished,
    required this.isPaused,
    required this.isBoostActive,
  });

  final double width;
  final double height;
  final ValueNotifier<int> duration;
  final ValueNotifier<int> onReset;
  final ValueNotifier<bool> isFinished;
  final ValueNotifier<bool> isPaused;
  final bool isBoostActive;

  @override
  State<KartyTimeBar> createState() => _KartyTimeBarState();
}

class _KartyTimeBarState extends State<KartyTimeBar> {
  static const _progressColor = Color(0xFF93D334);
  static const _progressTrackColor = Color(0xFFF4F6FB);

  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    widget.onReset.addListener(_resetProgress);
    widget.isPaused.addListener(_onPauseChanged);
  }

  @override
  void didUpdateWidget(covariant KartyTimeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBoostActive != widget.isBoostActive &&
        !widget.isPaused.value &&
        _progress < 1) {
      _startTimer();
    }
  }

  Color _currentBarColor() {
    if (_progress < 0.6) {
      return Color.lerp(
            _progressColor,
            const Color(0xFFFDC041),
            _progress / 0.6,
          ) ??
          _progressColor;
    }

    return Color.lerp(
          const Color(0xFFFDC041),
          const Color(0xFFF52A2A),
          (_progress - 0.6) / 0.4,
        ) ??
        const Color(0xFFF52A2A);
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isPaused.value || widget.duration.value <= 0) return;
    final speedFactor = widget.isBoostActive ? 0.75 : 1.0;
    final intervalMilliseconds =
        ((widget.duration.value * 10) / speedFactor).round();

    _timer = Timer.periodic(
      Duration(milliseconds: intervalMilliseconds),
      (timer) {
        if (!mounted) return;
        setState(() {
          _progress += 0.01;
          if (_progress >= 1) {
            _progress = 1;
            timer.cancel();
            widget.isFinished.value = true;
          }
        });
      },
    );
  }

  void _onPauseChanged() {
    if (widget.isPaused.value) {
      _timer?.cancel();
      return;
    }
    if (_progress < 1) _startTimer();
  }

  void _resetProgress() {
    if (!mounted) return;
    setState(() {
      _progress = 0;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.onReset.removeListener(_resetProgress);
    widget.isPaused.removeListener(_onPauseChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bu çubuk kartın cevap süresini gösterir; boost süresini değil. Boost
    // açıkken maviye dönmesi ve ucunda şimşek taşıması iki ayrı zamanı tek
    // nesneymiş gibi gösteriyordu. Boost'un kalan süresi artık kart
    // köşelerindeki iki şimşekten okunuyor; zaman çubuğu kendi anlamını korur.
    final barColor = _currentBarColor();
    final barRadius = BorderRadius.circular(widget.height / 2);
    final fillWidth = widget.width * _progress;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _progressTrackColor,
              borderRadius: barRadius,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: fillWidth,
            height: widget.height,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: barRadius,
              boxShadow: [
                BoxShadow(
                  color: barColor.withValues(alpha: 0.14),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(
                  left: widget.height * 0.34,
                  right: widget.height * 0.34,
                  top: widget.height * 0.12,
                ),
                height: widget.height * 0.22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: barRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
