import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/karty_card_rim.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/hourglass_mark.dart';
import 'package:lingualloop/ui/widgets/karty_play_surface.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_boost_button_affordance.dart';
import 'package:lingualloop/ui/widgets/karty_boost_edge_meter.dart';

class SwipableCard extends StatefulWidget {
  final Karty karty;
  final KartyCardLayout? layout;
  final bool showInlineRestartAction;

  /// Kelimenin telaffuzu. `null` ise buton çizilmiyor — sesi üretilmemiş
  /// kartta ölü kontrol bırakmıyoruz.
  final VoidCallback? onPronounce;
  final Offset position;
  final double rotation;
  final bool showRestartState;
  final bool isAdvancingDeck;
  final bool boostEnabled;
  final int boostCharge;
  final int boostChargeGoal;
  final bool isBoostReady;
  final bool isBoostActive;
  final bool isBoostActivating;
  final GlobalKey? topLeftBoostAnchorKey;
  final GlobalKey? bottomRightBoostAnchorKey;
  final ValueListenable<double> boostProgress;
  final VoidCallback onRestart;
  final VoidCallback onBoostTap;
  final ValueNotifier<bool> isTrueAnswerBlurActive;
  final ValueNotifier<bool> isFalseAnswerBlurActive;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  SwipableCard({
    Key? key,
    required this.karty,
    this.layout,
    this.showInlineRestartAction = true,
    this.onPronounce,
    required this.position,
    required this.rotation,
    required this.showRestartState,
    required this.isAdvancingDeck,
    required this.boostEnabled,
    required this.boostCharge,
    required this.boostChargeGoal,
    required this.isBoostReady,
    required this.isBoostActive,
    required this.isBoostActivating,
    this.topLeftBoostAnchorKey,
    this.bottomRightBoostAnchorKey,
    required this.boostProgress,
    required this.onRestart,
    required this.onBoostTap,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isTrueAnswerBlurActive,
    required this.isFalseAnswerBlurActive,
  }) : super(key: key);

  @override
  _SwipableCardState createState() => _SwipableCardState();
}

class _SwipableCardState extends State<SwipableCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addBlurListeners();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Yanlış cevabın **tek** hareketi: kısa bir "hayır" jesti.
    //
    // Eskiden üç sinyal aynı anda çalışıyordu — sarsıntı, kızarma ve
    // küçülme. Üçü birlikte cezalandırıcı okunuyordu; oysa hata öğrenmenin
    // parçası ve kullanıcı hata yaparken güvende hissetmeli. Kızarma ve
    // küçülme kaldırıldı; **sarsıntı commit'teki orijinal değerlerinde
    // bırakıldı** (±10 px, 400 ms) — bir tur 7/320'ye indirdim, kullanıcı
    // geri aldırdı.
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 20),
    ]).animate(_shakeController);
  }

  void _addBlurListeners() {
    widget.isTrueAnswerBlurActive.addListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.addListener(_handleFalseAnswerBlur);
  }

  void _handleTrueAnswerBlur() {
    // **Buraya `setState` konmaz.** Bu bir `ValueNotifier` dinleyicisi ve
    // build/layout fazının içinde tetiklenebiliyor; `setState() called
    // during build` istisnası alt ağacı kurulamaz hâle getiriyor — kart boş
    // kalıyor, görsel gelmiyor, ekran takılıyor. Bir tur doğru cevabın
    // yeşilini burada bir bayrakla tutmaya çalıştım ve tam bu oldu.
    //
    // Dinleyici yalnızca kontrolcü sürüyor; renk değişimi build tarafında
    // `ValueListenableBuilder` ile okunuyor.
    if (widget.isTrueAnswerBlurActive.value) {
      _scaleController.forward(from: 0);
    } else {
      _scaleController.reverse(from: 1);
    }
  }

  void _handleFalseAnswerBlur() {
    if (widget.isFalseAnswerBlurActive.value) {
      // Yanlış cevabın **tek** kart hareketi: kısa "hayır" jesti.
      //
      // Çerçeveyi kızartmak da denendi ve kaldırıldı: o, kartın **kendi
      // malzemesini** değiştiriyor — beyaz çerçeve + gradyan yüz kartın
      // kimliği. Yanlış olan kart değil, verilen cevap; geri bildirim
      // kartın **dışındaki** katmana ait (`KartyCardFeedbackEffect`).
      // Üstelik ikisi neredeyse aynı yerde göründüğü için ayırt
      // edilemiyorlardı.
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.isTrueAnswerBlurActive.removeListener(_handleTrueAnswerBlur);
    widget.isFalseAnswerBlurActive.removeListener(_handleFalseAnswerBlur);
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Boost'un tek kalıcı görsel nesnesi kartın iki köşesindeki şimşeklerdir.
  /// Aynı çift arka kart katmanında da çizildiği için deste hareketinde
  /// katmanlı görünür; kart yüzüne ayrı bir ilerleme paneli yapıştırılmaz.
  Widget _boostEdgeMeter({
    required double scale,
    required bool interactive,
  }) {
    return KartyBoostEdgeMeter(
      scale: scale,
      charge: widget.boostCharge,
      chargeGoal: widget.boostChargeGoal,
      isReady: widget.isBoostReady,
      isActive: widget.isBoostActive,
      isActivating: widget.isBoostActivating,
      boostProgress: widget.boostProgress,
      onTap: widget.onBoostTap,
      interactive: interactive,
      topLeftAnchorKey: interactive ? widget.topLeftBoostAnchorKey : null,
      bottomRightAnchorKey:
          interactive ? widget.bottomRightBoostAnchorKey : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 750;
    final cardWidth = widget.layout?.size.width ?? 535 * scale;
    final cardHeight = widget.layout?.size.height ?? 802 * scale;
    final layerOffset = widget.layout?.layerOffset ?? 44 * scale;
    final titleGap = widget.layout?.titleToCardGap ?? 120 * scale;
    final borderWidth = widget.layout?.borderWidth ?? 28 * scale;
    final borderRadius = BorderRadius.circular(52.5 * scale);
    final innerBorderRadius = BorderRadius.circular(29.25 * scale);
    const deckAnimationDuration = Duration(milliseconds: 280);
    // CSS 135deg is a 45-degree axis even on a tall card. A simple
    // topLeft/bottomRight gradient would stretch that angle with the card.
    final innerWidth = cardWidth - 2 * borderWidth;
    final innerHeight = cardHeight - 2 * borderWidth;
    final gradientX = (innerWidth + innerHeight) / (2 * innerWidth);
    final gradientY = (innerWidth + innerHeight) / (2 * innerHeight);
    final cardGradient = LinearGradient(
      colors: const [
        Color(0xFF68D73D),
        Color(0xFF56BEEA),
        Color(0xFFA647F0),
        Color(0xFFFDC041)
      ],
      stops: const [0.02, 0.38, 0.68, 1],
      begin: Alignment(-gradientX, -gradientY),
      end: Alignment(gradientX, gradientY),
    );
    double layerWidth(int level) {
      if (level == 0) {
        return cardWidth;
      }

      return cardWidth * (1 - .06 * level);
    }

    return GestureDetector(
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      child: SizedBox(
        width: 750 * scale,
        height: titleGap + cardHeight + layerOffset * 2,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: widget.isFalseAnswerBlurActive,
              builder: (context, isFalseActive, _) {
                return Positioned(
                  top: isFalseActive ? -58 * scale : -34 * scale,
                  child: AnimatedOpacity(
                    opacity: isFalseActive ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset:
                          isFalseActive ? Offset.zero : const Offset(0, 0.7),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: _KartyWordTitle(
                        text: widget.karty.correctText,
                        scale: scale,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 30 * scale,
              right: 30 * scale,
              child: KartyFeedbackWord(
                article: widget.karty.article,
                text: widget.karty.questionText,
                scale: scale,
                isCorrectActive: widget.isTrueAnswerBlurActive,
                isWrongActive: widget.isFalseAnswerBlurActive,
                onPronounce: widget.onPronounce,
              ),
            ),
            Positioned(
              top: titleGap,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight + (layerOffset * 2),
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 2; i >= 1; i--)
                      AnimatedPositioned(
                        duration: deckAnimationDuration,
                        curve: Curves.easeOutCubic,
                        top: widget.isAdvancingDeck
                            ? layerOffset * (i - 1)
                            : layerOffset * i,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: deckAnimationDuration,
                              curve: Curves.easeOutCubic,
                              width: widget.isAdvancingDeck
                                  ? layerWidth(i - 1)
                                  : layerWidth(i),
                              height: cardHeight,
                              decoration: BoxDecoration(
                                color: i == 2
                                    ? const Color(0xFFC2C6CD)
                                    : const Color(0xFFD8DCE4),
                                borderRadius: borderRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: i == 2
                                        ? const Color(0xFF8D959E)
                                        : const Color(0xFF9DA5AF),
                                    offset: Offset(0, 7.5 * scale),
                                  )
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: EdgeInsets.all(borderWidth),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: cardGradient,
                                    borderRadius: innerBorderRadius,
                                    border: Border.all(
                                      color: const Color(0x25041227),
                                      width: 3.75 * scale,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                ),
                              ),
                            ),
                            // Aynı köşe çifti arka kartta da yaşar. Ön kart
                            // kayınca bu çift yeni kartla birlikte öne gelir;
                            // kullanıcının sevdiği stack/continuity buradan
                            // doğar. i=2'ye kopyalanmaz, aksi hâlde köşeler
                            // ikon yığınına dönüşür.
                            if (i == 1 && widget.boostEnabled)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _boostEdgeMeter(
                                    scale: scale,
                                    interactive: false,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    AnimatedPositioned(
                      duration: deckAnimationDuration,
                      curve: Curves.easeOutCubic,
                      top: widget.isAdvancingDeck ? 0 : layerOffset,
                      left: widget.isAdvancingDeck
                          ? 0
                          : (cardWidth - layerWidth(1)) / 2,
                      width: widget.isAdvancingDeck ? cardWidth : layerWidth(1),
                      height: cardHeight,
                      child: KartyCardFeedbackEffect(
                        scale: scale,
                        isWrongActive: widget.isFalseAnswerBlurActive,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _scaleController,
                        _shakeController,
                      ]),
                      // ## `child` her karede yeniden kurulmaz — renk
                      // ## bu yüzden hiç animasyon olmuyordu
                      //
                      // `AnimatedBuilder`'ın `child` parametresi **bir kez**
                      // kurulup builder'a olduğu gibi geçiliyor; bu bilinçli
                      // bir eniyileme. Ama kartın çerçeve rengi
                      // (`_colorAnimation.value`) o `child`'ın içinde
                      // okunuyordu, yani değeri **build anında donuyordu**.
                      // Yanlış cevabın kızarması pratikte hiç görünmüyordu;
                      // yalnız başka bir sebeple yeniden build olursa
                      // rastgele beliriyordu.
                      //
                      // Çözüm: renge bağlı olan `Container` builder'ın
                      // **içine** taşındı. Ağır olan iç yığın (`child`) hâlâ
                      // dışarıda kalıyor, yani eniyileme korunuyor —
                      // yalnızca dekorasyon her karede yeniden hesaplanıyor.
                      builder: (context, child) {
                        return Transform.translate(
                          offset: widget.position +
                              Offset(_shakeAnimation.value, 0),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: widget.rotation,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: widget.isTrueAnswerBlurActive,
                                builder: (context, isCorrect, _) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeOut,
                                        width: cardWidth,
                                        height: cardHeight,
                                        decoration: BoxDecoration(
                                          // Doğru cevap kartın malzemesini
                                          // boyamaz; uygulamadaki butonlar gibi
                                          // yalnız alt kalınlık bandı yeşile
                                          // döner. Bu yerel ve tek bakışta
                                          // anlaşılan onay sinyalidir.
                                          color: Colors.white,
                                          borderRadius: borderRadius,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: .267),
                                              blurRadius: 22.5 * scale,
                                              offset: Offset(0, 18.75 * scale),
                                            ),
                                            BoxShadow(
                                              color: isCorrect
                                                  ? const Color(0xFF628C22)
                                                  : const Color(0xFFBDC5D0),
                                              offset: Offset(0, 7.5 * scale),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: CustomPaint(
                                          painter: KartyCardRimPainter(
                                              radius: 52.5 * scale),
                                          child: child,
                                        ),
                                      ),
                                      // Köşe şimşekleri kartın kırpılan yüz
                                      // katmanının dışında kalır. Böylece
                                      // hacimli kenarları ve arka karttaki
                                      // kopyaları kesilmeden stacklenir.
                                      if (widget.boostEnabled &&
                                          !widget.showRestartState)
                                        Positioned.fill(
                                          child: _boostEdgeMeter(
                                            scale: scale,
                                            interactive: true,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      // Ağır iç yığın: bir kez kuruluyor, her karede
                      // yeniden çizilmiyor.
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(borderWidth),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: cardGradient,
                                borderRadius: innerBorderRadius,
                                border: Border.all(
                                  color: const Color(0x25041227),
                                  width: 3.75 * scale,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Zaman aşımında kart yüzü karartılır.
                                  // Ayrı bir katman olarak duruyor çünkü
                                  // karartma **kart yüzeyine** ait, üstteki
                                  // bloğa değil; blokla birlikte çizilseydi
                                  // kartın kenarlarına kadar uzanamazdı.
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        opacity:
                                            widget.showRestartState ? 1 : 0,
                                        child: const ColoredBox(
                                          color: Color(0xB8041227),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    top: widget.showRestartState
                                        ? 0
                                        : innerHeight * .09,
                                    bottom: widget.showRestartState
                                        ? 0
                                        : innerHeight * .10,
                                    child: Center(
                                        child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeOut,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.94,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: widget.showRestartState
                                          ? Column(
                                              key: const ValueKey(
                                                  'restart-block'),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                HourglassMark(
                                                    size: 150 * scale),
                                                SizedBox(height: 26 * scale),
                                                Text(
                                                  'Süre doldu',
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFFE9EEF5),
                                                    fontFamily: AppTypography
                                                        .displayFamily,
                                                    fontSize: 52.5 * scale,
                                                    fontWeight:
                                                        AppTypography.heading,
                                                  ),
                                                ),
                                                if (widget
                                                    .showInlineRestartAction) ...[
                                                  SizedBox(height: 30 * scale),
                                                  // Yeşil kullanılamaz: bu
                                                  // ekranda yeşil "doğru
                                                  // cevap" demek ve zaman
                                                  // aşımı bir başarı değil.
                                                  DepthPressableButton(
                                                    text: 'TEKRAR DENE',
                                                    width: 260 * scale,
                                                    height: 86 * scale,
                                                    radius: 24 * scale,
                                                    shadowOffset: 10 * scale,
                                                    backgroundColor:
                                                        const Color(0xFF1CB1F5),
                                                    shadowColor:
                                                        const Color(0xFF1B84B5),
                                                    fontSize: 26 * scale,
                                                    fontWeight:
                                                        AppTypography.action,
                                                    onPressed: widget.onRestart,
                                                  ),
                                                ],
                                              ],
                                            )
                                          : Image.file(
                                              File(widget.karty.kartyUrl),
                                              // Anahtar **sabit**: bu
                                              // switcher'ın işi kart↔kart
                                              // değil, görsel ↔ "süre
                                              // doldu" hâli arasında
                                              // geçiş yapmak.
                                              //
                                              // Anahtar karta özel
                                              // olduğunda her kart
                                              // değişimi bir geçiş
                                              // tetikliyor ve eski görsel
                                              // 220 ms solarak kalıyordu —
                                              // "yeni karta geçerken eski
                                              // kartın resmi bir an
                                              // görünüyor" belirtisi
                                              // buydu.
                                              key:
                                                  const ValueKey('karty-image'),
                                              fit: BoxFit.contain,
                                              width: (cardWidth -
                                                      2 * borderWidth) *
                                                  .92,
                                              height: innerHeight * .81,
                                            ),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yanlış cevaptan sonra beliren **doğru yazım** ifşası.
///
/// Artikel hapı **bilerek yok**: bu ekranda yanlış olan şey artikel değil,
/// kelimenin yazımı. Hap burada da dursaydı kullanıcı hatasını ararken
/// gözünü önce artikele götürürdü — ifşanın tek işi doğru yazımı
/// göstermek. Hap, sorunun kendisiyle birlikte yukarıda zaten duruyor
/// (`KartyFeedbackWord`).
class _KartyWordTitle extends StatelessWidget {
  const _KartyWordTitle({
    required this.text,
    required this.scale,
  });

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 54 * scale,
            fontWeight: AppTypography.word,
            fontFamily: AppTypography.family,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// Eski sıvı şimşek, yeni tek-parça boost şeridi doğrulandıktan sonra
// tamamen silinecek geri dönüş referansıdır; üretim ağacında kullanılmaz.
// ignore: unused_element
class _KartyBoostBolt extends StatelessWidget {
  const _KartyBoostBolt({
    required this.scale,
    required this.charge,
    required this.chargeGoal,
    required this.boostProgress,
    required this.isReady,
    required this.isActive,
    required this.onTap,
  });

  final double scale;
  final int charge;
  final int chargeGoal;
  final ValueListenable<double> boostProgress;
  final bool isReady;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = 68 * scale;
    final height = 90 * scale;

    return ValueListenableBuilder<double>(
      valueListenable: boostProgress,
      builder: (context, remainingBoost, child) {
        final fill = isActive
            ? remainingBoost.clamp(0.0, 1.0)
            : isReady
                ? 1.0
                : (charge / chargeGoal).clamp(0.0, 1.0);

        return KartyBoostButtonAffordance(
          scale: scale,
          width: width,
          height: height,
          isReady: isReady,
          isActive: isActive,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fill),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, animatedFill, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(3 * scale, 5 * scale),
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 4 * scale,
                          sigmaY: 4 * scale,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.32),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/boost-bolt.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (isReady || isActive)
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 7 * scale,
                          sigmaY: 7 * scale,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            // Şimşek burada bir **simge** değil, enerjinin
                            // **kaynağı**: dolduğunda karta boşalan enerji
                            // ondan çıkıyor. §5'in "şimşek beyazdır" kuralı
                            // simge kullanımları için (lig rozeti, görev
                            // ikonu, maskot); burada uygulanınca kaynak ile
                            // çıkan enerji ayrı renkte kaldı ve bağ koptu.
                            //
                            // Boost enerjisi accent mavi olduğu için şimşek
                            // de o ailede.
                            const Color(0xFF6BD1FF).withValues(alpha: 0.92),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/boost-bolt.png',
                            width: width,
                            height: height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    _BoltLiquidLayer(
                      fill: animatedFill,
                      width: width,
                      height: height,
                      isFull: isReady || isActive,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BoltLiquidLayer extends StatefulWidget {
  const _BoltLiquidLayer({
    required this.fill,
    required this.width,
    required this.height,
    required this.isFull,
  });

  final double fill;
  final double width;
  final double height;
  final bool isFull;

  @override
  State<_BoltLiquidLayer> createState() => _BoltLiquidLayerState();
}

class _BoltLiquidLayerState extends State<_BoltLiquidLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value;
        final liquidColor =
            widget.isFull ? const Color(0xFF6BD1FF) : const Color(0xFF2E6C90);

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF253143),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/icons/boost-bolt.png',
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.contain,
                ),
              ),
              ClipPath(
                clipper: _BoltLiquidClipper(
                  fill: widget.fill,
                  phase: phase,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        liquidColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/icons/boost-bolt.png',
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (widget.fill > 0)
                      CustomPaint(
                        size: Size(widget.width, widget.height),
                        painter: _BoltBubblePainter(
                          phase: phase,
                          intensity: widget.isFull ? 1 : 0.62,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoltLiquidClipper extends CustomClipper<Path> {
  const _BoltLiquidClipper({
    required this.fill,
    required this.phase,
  });

  final double fill;
  final double phase;

  @override
  Path getClip(Size size) {
    final clampedFill = fill.clamp(0.0, 1.0);
    final surfaceY = size.height * (1 - clampedFill);
    final amplitude = size.height * 0.025;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, surfaceY);

    const steps = 18;
    for (var index = 0; index <= steps; index++) {
      final x = size.width * index / steps;
      final wave =
          math.sin((index / steps * math.pi * 2) + phase * math.pi * 2);
      path.lineTo(x, surfaceY + wave * amplitude);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BoltLiquidClipper oldClipper) {
    return oldClipper.fill != fill || oldClipper.phase != phase;
  }
}

class _BoltBubblePainter extends CustomPainter {
  const _BoltBubblePainter({
    required this.phase,
    required this.intensity,
  });

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    const bubbles = [
      (0.38, 0.79, 0.036, 0.0),
      (0.53, 0.72, 0.027, 0.18),
      (0.45, 0.61, 0.042, 0.36),
      (0.61, 0.53, 0.023, 0.55),
      (0.49, 0.43, 0.032, 0.72),
      (0.57, 0.33, 0.02, 0.87),
    ];

    for (var index = 0; index < bubbles.length; index++) {
      final bubble = bubbles[index];
      final travel = (phase + bubble.$4) % 1;
      final opacity = math.sin(travel * math.pi).clamp(0.0, 1.0);
      final sway =
          math.sin((travel * math.pi * 2) + index) * size.width * 0.025;
      final center = Offset(
        size.width * bubble.$1 + sway,
        size.height * (bubble.$2 - travel * 0.24),
      );
      final radius = size.width * bubble.$3 * (1 - travel * 0.2);
      final fillPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.3 * intensity)
        ..style = PaintingStyle.fill;
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.82 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.012);

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoltBubblePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
