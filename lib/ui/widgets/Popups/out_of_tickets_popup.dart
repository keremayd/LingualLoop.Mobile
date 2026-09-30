import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/premium_ticket_mark.dart';
import 'package:lingualloop/ui/widgets/quest_flag_mark.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/ticket_with_count.dart';

/// Bilet bittiğinde açılan pencere.
///
/// Bilet oyuna giriş bedelidir; bitince oyun açılmaz. Bu pencere o duvarı
/// açıklar ve **dört yol** sunar — Duolingo'nun kalp akışıyla aynı yapı:
///
/// | Duolingo | Bizde |
/// |---|---|
/// | Bekle (geri sayım) | Sonraki bilet — geri sayım |
/// | Pratik yap → anında kalp | **Rövanş oyna → +1 bilet** |
/// | Gem ile doldur | Görevleri bitir → bilet |
/// | Super ("sınırsız kalp") | Premium ("biletin hiç bitmesin") |
///
/// **Kritik olan ikinci satır.** Duolingo'nun ücretsiz yolu *anlık ve
/// tekrarlanabilir*: bir pratik yap, kalbini hemen geri al. Bizde eskiden
/// yalnız "görevleri tamamla" vardı; görevlerini bitirmiş kullanıcı için
/// pencere sadece beklemeye indirgeniyordu. Rövanş o boşluğu kapatıyor ve
/// sömürülemez — yalnız gerçekten bekleyen yanlış kart varsa çalışır.
///
/// Ödemeyen kullanıcı köşeye sıkıştırılmaz: üç ücretsiz yol da her zaman
/// görünür. Baskı var, duvar yok.
Future<void> showOutOfTicketsPopup(
  BuildContext context, {
  required DateTime? nextTicketAt,
  required Future<bool> Function() onRefreshTickets,
  required VoidCallback onGoToReview,
  required VoidCallback onGoToQuests,
  required VoidCallback onGoPremium,
  int? questTickets,
  bool reviewAvailable = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xFF041227).withValues(alpha: 0.86),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.06,
      ),
      child: OutOfTicketsCard(
        nextTicketAt: nextTicketAt,
        onRefreshTickets: onRefreshTickets,
        onTicketsReady: () => Navigator.of(context).pop(),
        questTickets: questTickets,
        reviewAvailable: reviewAvailable,
        onGoToReview: () {
          Navigator.of(context).pop();
          onGoToReview();
        },
        onGoToQuests: () {
          Navigator.of(context).pop();
          onGoToQuests();
        },
        onGoPremium: () {
          Navigator.of(context).pop();
          onGoPremium();
        },
      ),
    ),
  );
}

/// Pencerenin içeriği. `Dialog`'dan ayrı bir widget çünkü golden önizlemesi
/// kartı tek başına render edebilsin.
class OutOfTicketsCard extends StatefulWidget {
  const OutOfTicketsCard({
    super.key,
    required this.nextTicketAt,
    required this.onRefreshTickets,
    required this.onTicketsReady,
    required this.onGoToReview,
    required this.onGoToQuests,
    required this.onGoPremium,
    this.questTickets,
    this.reviewAvailable = true,
  });

  final DateTime? nextTicketAt;
  final Future<bool> Function() onRefreshTickets;
  final VoidCallback onTicketsReady;

  /// Bugün görevlerden kazanılabilecek bilet. Bilinmiyorsa sayı yazılmaz —
  /// "0 bilet" göstermek yolu kapalı gibi gösterirdi.
  final int? questTickets;
  final bool reviewAvailable;

  final VoidCallback onGoToReview;
  final VoidCallback onGoToQuests;
  final VoidCallback onGoPremium;

  @override
  State<OutOfTicketsCard> createState() => _OutOfTicketsCardState();
}

class _OutOfTicketsCardState extends State<OutOfTicketsCard>
    with SingleTickerProviderStateMixin {
  static const _cardFace = Color(0xFF041227);
  static const _cardBorder = Color(0xFF0B2143);
  static const _rowFace = Color(0xFF07182F);
  static const _muted = Color(0xFF8FA0B5);
  static const _countdownValue = Color(0xFFE9EEF5);
  static const _urgent = Color(0xFFFF6B3D);
  static const _accent = Color(0xFF1CB1F5);
  static const _accentDeep = Color(0xFF1B84B5);

  late final AnimationController _entry;
  Timer? _tick;
  Timer? _refreshAt;
  bool _refreshInFlight = false;
  bool _readyHandled = false;

  @override
  void initState() {
    super.initState();
    // Giriş: kayarak değil büyüyerek. Kayma "bir liste öğesi geldi" der,
    // büyüme "bir an oldu" der — bu bir an.
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    // Geri sayım dakikada bir tazelenir; saniye göstermiyoruz.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    _scheduleTicketRefresh();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _refreshAt?.cancel();
    _entry.dispose();
    super.dispose();
  }

  void _scheduleTicketRefresh() {
    final at = widget.nextTicketAt;
    if (at == null) return;

    final delay = at.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTicketBalance();
      });
      return;
    }

    // Metin yaklaşık dakika gösterebilir; gerçek istek milisaniyesine kadar
    // sunucunun verdiği yenilenme anında çalışır.
    _refreshAt = Timer(delay, _refreshTicketBalance);
  }

  Future<void> _refreshTicketBalance() async {
    if (!mounted || _refreshInFlight || _readyHandled) return;
    _refreshInFlight = true;

    // Sayaç sıfırda bir başarı iddiası göstermez; sunucudan cevap gelene kadar
    // yalnız kısa bir yenileme durumu görünür.
    setState(() {});

    var hasTicket = false;
    try {
      hasTicket = await widget.onRefreshTickets();
    } catch (_) {
      // Geçici bağlantı hatasında popup açık kalır ve güvenli aralıkla dener.
    } finally {
      _refreshInFlight = false;
    }

    if (!mounted) return;
    if (hasTicket) {
      _readyHandled = true;
      widget.onTicketsReady();
      return;
    }

    // Eski bir sunucu sürümü veya anlık ağ gecikmesi bile kullanıcıyı yanlış
    // "hazır" durumunda bırakmasın. Gerçek bakiye gelene kadar tekrar sorgula.
    _refreshAt = Timer(const Duration(seconds: 5), _refreshTicketBalance);
  }

  Duration? get _remaining {
    final at = widget.nextTicketAt;
    if (at == null) return null;
    final diff = at.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// §2.10: renk dekorasyon değil aciliyet sinyali. Süre son 15 dakikaya
  /// düştüğünde sıcak tona geçer — "neredeyse geldi" demek için.
  bool get _isImminent {
    final left = _remaining;
    return left != null && left > Duration.zero && left.inMinutes <= 15;
  }

  bool get _renewalDue => _remaining == Duration.zero;

  String get _countdownText {
    final left = _remaining;
    if (left == null) return 'Birazdan';
    if (left == Duration.zero) return 'Bilet yenileniyor';
    if (left.inHours > 0) {
      return '${left.inHours} sa ${left.inMinutes - left.inHours * 60} dk';
    }
    if (left.inMinutes < 1) return '<1 dk';
    return '${left.inMinutes} dk';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;

    return ScaleTransition(
      scale: Tween(begin: 0.86, end: 1.0).animate(
        CurvedAnimation(parent: _entry, curve: Curves.easeOutBack),
      ),
      child: FadeTransition(
        opacity: _entry,
        child: _card(scale),
      ),
    );
  }

  /// Kart genişliği tasarım biriminde: 750 referanstan kenar boşlukları
  /// (44×2) düşülmüş hâli. Sabit olmalı çünkü içindeki depth-press buton
  /// sonsuz genişlik kabul etmiyor.
  static const _cardWidth = 662.0;
  static const _cardPadding = 34.0;
  static const _contentWidth = _cardWidth - _cardPadding * 2;

  /// Kart dili §2.3: yüz sayfa zemini, kontur `0B2143`, altta taban dudağı.
  Widget _card(double scale) {
    final radius = BorderRadius.circular(AppShapeStyle.cardRadius(34 * scale));

    return Container(
      width: _cardWidth * scale,
      decoration: BoxDecoration(color: _cardBorder, borderRadius: radius),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(8 * scale)),
      child: Container(
        decoration: BoxDecoration(
          color: _cardFace,
          borderRadius: radius,
          border: Border.all(
              color: _cardBorder, width: AppShapeStyle.outline(2 * scale)),
        ),
        padding: EdgeInsets.fromLTRB(
          _cardPadding * scale,
          38 * scale,
          _cardPadding * scale,
          28 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _depletedTicketMascot(scale),
            SizedBox(height: 10 * scale),
            Text(
              'Biletin bitti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46 * scale,
                fontWeight: AppTypography.heading,
                fontFamily: AppTypography.displayFamily,
                height: 1,
              ),
            ),
            SizedBox(height: 14 * scale),
            _countdownRow(scale),
            SizedBox(height: 26 * scale),

            // Ücretsiz kazanma yolları. Rövanş önce geliyor çünkü **anlık**
            // sonuç veriyor; görevler günlük ve bitmiş olabilir.
            _earnRow(
              scale,
              icon: QuestIcon(questKey: 'review_two', size: 46 * scale),
              title: 'Rövanş oyna',
              subtitle: widget.reviewAvailable
                  ? 'Yanlışlarını tekrarla'
                  : 'Bekleyen rövanş kartın yok',
              reward: widget.reviewAvailable ? 1 : null,
              onTap: widget.reviewAvailable ? widget.onGoToReview : null,
            ),
            SizedBox(height: 12 * scale),
            _earnRow(
              scale,
              icon: QuestFlagMark(size: 44 * scale),
              title: 'Görevleri bitir',
              subtitle: 'Günlük görevlerden kazan',
              reward: widget.questTickets,
              onTap: widget.onGoToQuests,
            ),

            SizedBox(height: 24 * scale),
            DepthPressableButton(
              width: _contentWidth * scale,
              height: 120 * scale,
              radius: 24 * scale,
              shadowOffset: 9 * scale,
              backgroundColor: _accent,
              shadowColor: _accentDeep,
              fontSize: 28 * scale,
              fontWeight: AppTypography.action,
              onPressed: widget.onGoPremium,
              // Duolingo'nun premium dili iridescent olsa da tüm yüzeyi
              // gökkuşağı yapmak metin kontrastını ve Karty'nin kaplama
              // dilini bozar. Renk premium bilette, eylem accent yüzeyde.
              child: _premiumButtonContent(scale),
            ),
          ],
        ),
      ),
    );
  }

  /// Ücretsiz kazanma yolu — tek satır: ikon, ne olduğu, ödülü.
  ///
  /// Satır **§2.3 kart dilini** kullanıyor (iç panel tonu, kontur) ama
  /// depth-press değil: bunlar birer eylem değil **yönlendirme**; asıl eylem
  /// aşağıdaki yeşil buton. İkisi de çökseydi hangisinin birincil olduğu
  /// kaybolurdu.
  Widget _earnRow(
    double scale, {
    required Widget icon,
    required String title,
    required String subtitle,
    required int? reward,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(AppShapeStyle.cardRadius(20 * scale)),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: onTap == null ? 0.48 : 1,
          child: Container(
            width: _contentWidth * scale,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              color: _rowFace,
              borderRadius:
                  BorderRadius.circular(AppShapeStyle.cardRadius(20 * scale)),
              border: Border.all(
                  color: _cardBorder, width: AppShapeStyle.outline(2 * scale)),
            ),
            child: Row(
              children: [
                icon,
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27 * scale,
                          fontWeight: AppTypography.label,
                          fontFamily: AppTypography.family,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 21 * scale,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reward != null && reward > 0) ...[
                  SizedBox(width: 12 * scale),
                  // Rozet biletin altına taştığı için widget'ın geometrik
                  // merkezi bilet gövdesinin merkezinden aşağıdadır. Gövdeyi
                  // satır metniyle optik olarak ortalamak için bu küçük pay
                  // bilinçli olarak aşağı verilir.
                  Transform.translate(
                    offset: Offset(0, 7 * scale),
                    child: TicketWithCount(
                      scale: scale,
                      count: reward,
                      ticketWidth: 62,
                      badgeSize: 30,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Son biletin elde tutulamayacak kadar akışkanlaşması, kaybı nesnenin
  /// kendisi üzerinden anlatır. Görsel bileti zaten içerdiği için ayrıca
  /// `ticket.png` bindirilmez.
  Widget _depletedTicketMascot(double scale) {
    return SizedBox(
      height: 290 * scale,
      child: Image.asset(
        'assets/icons/mascot_ticket_melt.png',
        height: 290 * scale,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _countdownRow(double scale) {
    final color = _isImminent ? _urgent : _countdownValue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_renewalDue)
          SizedBox(
            width: 27 * scale,
            height: 27 * scale,
            child: CircularProgressIndicator(
              strokeWidth: 4 * scale,
              color: _countdownValue,
            ),
          )
        else
          Icon(
            Icons.hourglass_bottom_rounded,
            size: 30 * scale,
            color: _isImminent ? _urgent : _muted,
          ),
        SizedBox(width: 8 * scale),
        Text(
          _countdownText,
          style: TextStyle(
            color: color,
            fontSize: 27 * scale,
            fontWeight: AppTypography.number,
            fontFamily: AppTypography.family,
          ),
        ),
        if (!_renewalDue) ...[
          SizedBox(width: 8 * scale),
          Flexible(
            child: Text(
              'sonra yeni bilet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _muted,
                fontSize: 27 * scale,
                fontWeight: AppTypography.caption,
                fontFamily: AppTypography.family,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Premium vaadi ile eylemi tek yüzeyde toplar. Önceki sürümde aynı vaat
  /// bilgi kartında ve altındaki butonda iki kez anlatıldığı için popup uzuyor,
  /// iki parça da birbirinden kopuk görünüyordu.
  Widget _premiumButtonContent(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22 * scale),
      child: Row(
        children: [
          PremiumTicketMark(width: 108 * scale),
          SizedBox(width: 18 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BİLETİN HİÇ BİTMESİN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26 * scale,
                    fontWeight: AppTypography.action,
                    fontFamily: AppTypography.family,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 7 * scale),
                Text(
                  'Premium ile beklemeden oyna',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 20 * scale,
                    fontWeight: AppTypography.caption,
                    fontFamily: AppTypography.family,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
