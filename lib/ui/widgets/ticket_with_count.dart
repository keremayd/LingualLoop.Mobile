import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';

/// Yıldızlı bilet ve sağ-alt köşesinde adet rozeti.
///
/// Bilet kimliği korunur; adet yıldızın yerine yazılmaz. Görevler ekranındaki
/// ödül uçlarının ve bilet kazanma yönlendirmelerinin ortak gösterimidir.
class TicketWithCount extends StatelessWidget {
  const TicketWithCount({
    super.key,
    required this.scale,
    required this.count,
    required this.ticketWidth,
    required this.badgeSize,
    this.dim = false,
  });

  final double scale;
  final int count;
  final double ticketWidth;
  final double badgeSize;
  final bool dim;

  static const _aspect = 172 / 110;
  static const _background = Color(0xFF041227);
  static const _border = Color(0xFF0B2143);
  static const _gold = Color(0xFFFFC93A);
  static const _dimGold = Color(0xFFB87E00);
  static const _muted = Color(0xFF8FA0B5);

  @override
  Widget build(BuildContext context) {
    final w = ticketWidth * scale;
    final h = w / _aspect;
    final badge = badgeSize * scale;

    return SizedBox(
      width: w + badge * 0.42,
      height: h + badge * 0.34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: dim
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [_dimGold, _dimGold],
                    ).createShader(rect),
                    child: Image.asset(
                      'assets/icons/ticket.png',
                      width: w,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/icons/ticket.png',
                    width: w,
                    fit: BoxFit.contain,
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: _background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dim ? _border : _gold,
                  width: 2 * scale,
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(3 * scale),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: dim ? _muted : Colors.white,
                      fontFamily: AppTypography.family,
                      fontSize: badge * 0.62,
                      fontWeight: AppTypography.number,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
