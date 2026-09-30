import 'package:flutter/material.dart';

/// Basılabilir kartların ortak derinlik ve etkinlik davranışı.
///
/// Pasifken kart basılmış konumda, alt derinlik katmanı kapalı ve soluk durur.
/// Etkinleştiğinde yüz yukarı kalkar, derinlik katmanı belirir ve renkler
/// yumuşakça tam yoğunluğuna ulaşır. Etkinliğini kaybettiğinde de
/// aynı hareket tersine oynar; bu, Home'a dönüldüğünde biten Rövanş ve
/// Artikel Pusulası kartlarının bir anda durum değiştirmesini önler.
class PressableLayeredCard extends StatefulWidget {
  const PressableLayeredCard({
    super.key,
    required this.width,
    required this.height,
    required this.shadowOffset,
    required this.radius,
    required this.baseColor,
    required this.face,
    required this.onPressed,
    this.disabledOpacity = 0.58,
  });

  final double width;
  final double height;
  final double shadowOffset;
  final BorderRadius radius;
  final Color baseColor;
  final Widget face;
  final VoidCallback? onPressed;
  final double disabledOpacity;

  @override
  State<PressableLayeredCard> createState() => _PressableLayeredCardState();
}

class _PressableLayeredCardState extends State<PressableLayeredCard>
    with SingleTickerProviderStateMixin {
  static const _enableDuration = Duration(milliseconds: 260);
  static const _disableDuration = Duration(milliseconds: 380);

  bool _isPressed = false;
  late final AnimationController _availabilityController;
  late final Animation<double> _availability;

  bool get _isEnabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _availabilityController = AnimationController(
      vsync: this,
      duration: _enableDuration,
      reverseDuration: _disableDuration,
      value: _isEnabled ? 1 : 0,
    );
    _availability = CurvedAnimation(
      parent: _availabilityController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant PressableLayeredCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEnabled = oldWidget.onPressed != null;
    if (wasEnabled == _isEnabled) return;

    // Etkileşim yeni veri geldiği anda kapanır; görsel çökme devam ederken
    // kullanıcı artık boş bir oyuna giremez.
    if (!_isEnabled) {
      _isPressed = false;
      _availabilityController.reverse();
    } else {
      _availabilityController.forward();
    }
  }

  @override
  void dispose() {
    _availabilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceHeight = widget.height - widget.shadowOffset;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: AnimatedBuilder(
        animation: _availability,
        builder: (context, child) {
          final availability = _availability.value;
          final disabledOffset = (1 - availability) * widget.shadowOffset;
          final opacity = widget.disabledOpacity +
              ((1 - widget.disabledOpacity) * availability);

          return Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTapDown:
                  _isEnabled ? (_) => setState(() => _isPressed = true) : null,
              onTapCancel:
                  _isEnabled ? () => setState(() => _isPressed = false) : null,
              onTapUp: _isEnabled
                  ? (_) {
                      setState(() => _isPressed = false);
                      widget.onPressed!();
                    }
                  : null,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: widget.shadowOffset,
                      child: Opacity(
                        opacity: availability,
                        child: AnimatedOpacity(
                          // Basma geri bildiriminin mevcut mekaniği korunur:
                          // gölge yüzden önce kaybolur.
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
                    ),
                    Positioned(
                      left: 0,
                      top: disabledOffset,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOut,
                        offset: Offset(
                          0,
                          _isPressed ? widget.shadowOffset / faceHeight : 0,
                        ),
                        child: SizedBox(
                          width: widget.width,
                          height: faceHeight,
                          child: widget.face,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
