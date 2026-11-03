import 'package:flutter/material.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/clock_mark.dart';

/// Kalan süre kapsülü: saat + yalnız değer ("27 gün", "1 sa 36 dk").
///
/// Lig ve Görevler başlıkları **aynı** bileşeni kullanır. Bir dönem ikisi de
/// "⏳ 1 sa 36 dk sonra yenilenir" yazıyordu: köşedeki bir sayaç için uzun,
/// Material kum saati de çizilmiş simgelerin yanında düz kalıyordu. Duolingo
/// bu sayacı yalnız "⏱ 5 HOURS" diye yazar — anlamı konumu ve saat taşıyor.
///
/// Kapsül profildeki koruma hapıyla aynı (`0C2244`). §2.10: [urgent] iken
/// (son 2 saat) saat ve değer sıcak tona geçer.
class CountdownPill extends StatelessWidget {
  const CountdownPill({
    super.key,
    required this.scale,
    required this.value,
    required this.semanticLabel,
    this.urgent = false,
  });

  final double scale;
  final String value;

  /// Ekran okuyucu için tam cümle — görsel yalnız değeri gösteriyor.
  final String semanticLabel;
  final bool urgent;

  static const _pillColor = Color(0xFF0C2244);
  static const _valueColor = Color(0xFFE9EEF5);
  static const _urgentColor = Color(0xFFFF6B3D);

  @override
  Widget build(BuildContext context) {
    // Köşe yuvarlaklığı butonlarla aynı orandan: yükseklik sabit, yarıçap
    // AppButtonStyle'ın eylem oranından (kısa kenarın 36/131.25'i). Bir tur
    // kart yarıçapı (≈22 birim) verilmişti; 56 birimlik kapsülde neredeyse
    // tam yuvarlak bir hap gibi duruyordu.
    final height = 56 * scale;
    final radius = AppButtonStyle.resolve(
      width: double.infinity,
      totalHeight: height,
      legacyRadius: 18 * scale,
      legacyDepth: 0,
      roundedDepthOverride: 0,
      icon: false,
    ).radius;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _pillColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.fromLTRB(12 * scale, 0, 18 * scale, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClockMark(size: 38 * scale, urgent: urgent),
            SizedBox(width: 9 * scale),
            // Dar başlık sütununda taşmasın: sığmazsa ölçeklenerek küçülür.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: urgent ? _urgentColor : _valueColor,
                    fontSize: 26 * scale,
                    fontWeight: AppTypography.number,
                    fontFamily: AppTypography.family,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
