import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kartın boyu kalan alandan gelir; kısa ekranlarda cevaplar alta taşmaz.
class KartyCardLayout {
  const KartyCardLayout({
    required this.size,
    required this.titleToCardGap,
    required this.layerOffset,
    required this.borderWidth,
  });

  final Size size;
  final double titleToCardGap;
  final double layerOffset;
  final double borderWidth;
}

/// Önizleme ve gerçek oyun aynı güvenli alan / yerleşim hesabını kullanır.
class KartyPlaySurface extends StatelessWidget {
  const KartyPlaySurface({
    super.key,
    required this.header,
    required this.cardBuilder,
    required this.actions,
    this.isIntroducing = false,
    this.debugAction,
    this.reserveDebugSpace = kDebugMode,
    this.overlays = const [],
  });

  final Widget header;
  final Widget Function(KartyCardLayout layout) cardBuilder;
  final Widget actions;
  final bool isIntroducing;
  final Widget? debugAction;

  /// Stable for the whole session: hiding the debug action must not resize
  /// the deck on timeout, introduction, pause or retry.
  final bool reserveDebugSpace;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 750;
          final safe = MediaQuery.paddingOf(context);
          // Approved HTML: 1 cqw = 7.5 design units. Preserve its proportions,
          // then constrain the bottom controls to the device's safe area.
          final height = constraints.maxHeight;
          final headerTop = math.max(safe.top, height * .0758 - 4.875 * scale);
          final headerHeight = math.max(44.0, 84.75 * scale) + 4.875 * scale;
          final bottom = height - math.max(safe.bottom, 20 * scale);
          final debugHeight = math.max(44.0, height * .053);
          final debugTop = math.min(height * .92, bottom - debugHeight);
          final actionsHeight = 131.25 * scale;
          final actionsTop = math.min(
            height * (reserveDebugSpace ? .83 : .855),
            (reserveDebugSpace ? debugTop - 12 * scale : bottom - 22 * scale) -
                actionsHeight,
          );
          final cardTop = height * .19 + (height * .075 - 97.35 * scale) / 2;
          final deckTop = height * .282;
          final titleGap = deckTop - cardTop;
          final layerOffset = 30 * scale;
          final cardHeight = math.min(
            height * (reserveDebugSpace ? .48 : .508),
            actionsTop - 40 * scale - deckTop - 2 * layerOffset - 7.5 * scale,
          );
          final layout = KartyCardLayout(
            size: Size(601.5 * scale, math.max(160 * scale, cardHeight)),
            titleToCardGap: titleGap,
            layerOffset: layerOffset,
            borderWidth: 23.25 * scale,
          );
          return Stack(clipBehavior: Clip.none, children: [
            if (isIntroducing)
              Positioned(
                key: const ValueKey('karty-introduction-label'),
                top: cardTop - 42 * scale,
                left: 0,
                right: 0,
                child: Text('Yeni kelime',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color(0xFF8FA0B5),
                        fontFamily: AppTypography.family,
                        fontSize: 26 * scale,
                        fontWeight: AppTypography.caption)),
              ),
            Positioned(
                key: const ValueKey('karty-card-slot'),
                top: cardTop,
                left: 0,
                right: 0,
                child: cardBuilder(layout)),
            Positioned(
              key: const ValueKey('karty-actions-slot'),
              top: actionsTop,
              left: 97.5 * scale,
              right: 97.5 * scale,
              child: actions,
            ),
            if (debugAction != null)
              Positioned(
                  key: const ValueKey('karty-debug-slot'),
                  top: debugTop,
                  height: debugHeight,
                  left: 180 * scale,
                  right: 180 * scale,
                  child: debugAction!),
            ...overlays.map((overlay) => Positioned.fill(
                key: ValueKey(overlay.key ?? overlay.runtimeType),
                child: overlay)),
            // Menü eklenince zamanlayıcının State'i değişmemeli.
            Positioned(
              key: const ValueKey('karty-header-slot'),
              top: headerTop,
              left: 46.125 * scale,
              right: 46.125 * scale,
              height: headerHeight,
              child: header,
            ),
          ]);
        },
      );
}
