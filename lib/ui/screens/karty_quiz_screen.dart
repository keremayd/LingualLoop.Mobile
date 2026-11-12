import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/karty_session.dart';
import 'package:lingualloop/models/karty_session_summary.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/models/responses/KartySessionStatusResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/ui/screens/karty_session_summary_screen.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/cached_signed_image.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_boost_edge_meter.dart';
import 'package:lingualloop/ui/widgets/karty_question_parts.dart';
import 'package:lingualloop/ui/widgets/karty_question_card.dart';
import 'package:lingualloop/ui/widgets/hourglass_mark.dart';
import 'package:lingualloop/ui/widgets/karty_listen_player.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/karty_top_bar.dart';
import 'package:lingualloop/ui/widgets/karty_boost_activation_effect.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';
import 'package:lingualloop/ui/widgets/karty_success_celebration.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/ui/widgets/karty_play_surface.dart';
import 'package:lingualloop/ui/widgets/loading_skeleton.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'package:lingualloop/ui/widgets/karty_pause_overlay.dart';

import '../../services/UserService.dart';

/// Ekrandaki sorunun cevap durumu. Karta bağlı tutuluyor: deste ilerlerken
/// yeni kart, eski kartın seçimiyle çizilmesin.
class _QuestionAnswer {
  _QuestionAnswer(this.kartyId, String word)
      : tiles = kartyShuffledLetters(word, kartyId);

  final int kartyId;
  final List<String> tiles;
  int? optionId;
  String? article;

  /// Harf dizmede yuvalara sırayla konmuş karolar; yanlış harf de konabilir,
  /// yuvasına dokunulunca geri alınır.
  final List<int> placed = [];
  bool lettersFailed = false;

  String get spelled => placed.map((index) => tiles[index]).join();

  /// Kelimeyi veren karo sırası; aynı harften ikisi varsa ilki önce.
  List<int> solutionFor(String word) {
    final order = <int>[];
    for (final letter in word.split('')) {
      order.add(List.generate(tiles.length, (index) => index).firstWhere(
          (index) => tiles[index] == letter && !order.contains(index)));
    }
    return order;
  }
}

class KartyQuizScreen extends StatefulWidget {
  final bool reviewMode;

  /// Karty Yolu'ndan açıldıysa oyunun destesi; deste bitince özet çıkar.
  final KartySessionArgs? session;

  const KartyQuizScreen({super.key, this.reviewMode = false, this.session});

  @override
  _KartyQuizScreenState createState() => _KartyQuizScreenState();
}

class _KartyQuizScreenState extends State<KartyQuizScreen> {
  static const _backgroundColor = Color(0xFF041227);

  static const _boostChargeGoal = 5;
  static const _boostDurationMilliseconds = 20000;

  bool _answerLocked = false;
  bool _isDeckAdvancing = false;

  /// Deste kayması yalnız iki tam boy kart arasında okunuyor; soru düzeni
  /// değişecekse gövde sönüp yenisi beliriyor.
  bool _fadeBody = false;
  _QuestionAnswer? _answer;
  bool _isReviewEmpty = false;
  int _boostCharge = 0;
  int _boostRemainingMilliseconds = 0;
  int _reviewTotalStack = 0;
  int _reviewCompletedStack = 0;
  int _reviewRewardTickets = 0;
  bool _isBoostReady = false;
  bool _isBoostActive = false;
  bool _isBoostActivating = false;
  bool _didPrecacheReviewCompleteScene = false;
  Timer? _boostTimer;
  int streak = 0;
  final ValueNotifier<int> timeBarResetNotifier = ValueNotifier<int>(1);
  late ValueNotifier<int> duration = ValueNotifier<int>(0);
  final ValueNotifier<bool> isFinished = ValueNotifier(false);
  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  final ValueNotifier<bool> isTrueAnswerBlurActive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isFalseAnswerBlurActive =
      ValueNotifier<bool>(false);
  final ValueNotifier<double> boostProgress = ValueNotifier<double>(0);

  late KartyProvider kartyProvider;
  late KartyService kartyService;
  late UserService userService;
  late ProfileLearningStatsProvider profileLearningStatsProvider;
  late PronunciationService pronunciationService;
  late GameFeedbackService gameFeedback;

  /// Tanışma ve dinleme kartında sesin **bir kez** otomatik çalınmasını
  /// sağlar: aynı kart için ikinci kez tetiklenmesin diye son çalınan kart
  /// tutuluyor.
  /// `build` her setState'te koştuğu için bu koruma olmadan ses üst üste
  /// binerdi.
  int? _autoPlayedKartyId;

  /// Deste **bu ekran oturumu için** yüklendi mi.
  ///
  /// `KartyProvider` uygulama ömürlü ve destesini hafızada tutuyor;
  /// `initState` içindeki `reset()` bir `Future.microtask` içinde koştuğu
  /// için **ilk `build` ondan önce** çalışıyor ve `cards` hâlâ bir önceki
  /// oturumun kartını taşıyor. Otomatik seslendirme `build`'den tetiklendiği
  /// için o eski kartın sesini çalıyordu: kullanıcı Karty'den çıkıp
  /// girdiğinde önce bir önceki kelimeyi, sonra yenisini duyuyordu.
  ///
  /// Bayrak, yükleme bitene kadar seslendirmeyi kilitliyor.
  bool _deckReady = false;
  final GlobalKey<KartySuccessCelebrationState> _successCelebrationKey =
      GlobalKey();
  final GlobalKey<KartyBoostActivationEffectState> _boostActivationKey =
      GlobalKey();
  final GlobalKey _boostTopLeftAnchorKey = GlobalKey();
  final GlobalKey _boostBottomRightAnchorKey = GlobalKey();
  final GlobalKey _boostLeagueTargetKey = GlobalKey();
  bool _pauseMenuOpen = false;

  /// Karty Yolu oyununun sayaçları: deste bitince özette gösterilir.
  /// Puan XP ile lig puanının ikisi de (Karty'de aynı miktarda artarlar).
  int _sessionPoints = 0;
  int _sessionCorrect = 0;
  int _sessionAnswered = 0;
  final Set<int> _sessionWrongIds = {};

  /// Cevaplanan kelimeler; yalnız tekrar oyununun ve pratiğin özetinde
  /// karolar bunlar.
  final Map<int, KartyWord> _sessionWords = {};

  /// Pratik: vakti gelmiş tekrar yokken oyun baştan pratiktir, özetten
  /// sonra PRATİK YAP da pratiğe geçer. Bitişi sunucu değil tur uzunluğu
  /// belirler.
  late bool _practicing = !(widget.session?.hasWork ?? false);

  /// Pratik turu bu kadar cevapla biter, "Pratik tamam!" açılır. Turun sonu
  /// yokken on dakika oynayan kullanıcı "bunun sonu yok mu?" diye sordu
  /// (12 Kas 2026); Duolingo'da da pratik belli sayıda soruyla biter.
  static const _practiceRound = 10;

  /// Ünitenin bilinen son hâli: deste özetinden sonraki pratik turu
  /// özetinde de çubuk güncel çizilsin.
  KartyUnit? _unitNow;

  @override
  void initState() {
    super.initState();
    kartyProvider = Provider.of<KartyProvider>(context, listen: false);
    kartyService = Provider.of<KartyService>(context, listen: false);
    userService = Provider.of<UserService>(context, listen: false);
    profileLearningStatsProvider =
        Provider.of<ProfileLearningStatsProvider>(context, listen: false);
    pronunciationService =
        Provider.of<PronunciationService>(context, listen: false);
    gameFeedback = Provider.of<GameFeedbackService>(context, listen: false);
    unawaited(gameFeedback.preload());

    Future.microtask(() async {
      // Bilet sahnesi sürerken hazırlandıysa kartlar zaten iniyor.
      final prepared = widget.reviewMode
          ? null
          : kartyProvider.takePreparedLoad(
              unit: widget.session?.unit.number,
              deck: widget.session?.deck,
            );
      if (prepared == null) {
        kartyProvider.reset();
        // Yeni kelime yalnız Karty Yolu'ndaki şu anki desteden istenir.
        kartyProvider.startSession(
          unit: widget.session?.unit.number,
          deck: widget.session?.deck,
        );
      }
      if (widget.reviewMode) {
        setState(() {
          _reviewTotalStack =
              profileLearningStatsProvider.stats?.reviewPendingCount ?? 0;
          _reviewCompletedStack = 0;
        });
      }

      final isLoaded = await (prepared ??
          kartyProvider.loadKarty(
            context,
            reviewMode: widget.reviewMode,
          ));
      if (isLoaded) {
        if (mounted) setState(() => _deckReady = true);
        if (widget.reviewMode) {
          unawaited(
            profileLearningStatsProvider.refreshFromService(userService).then(
              (_) {
                if (!mounted) return;
                setState(() {
                  _reviewTotalStack =
                      profileLearningStatsProvider.stats?.reviewPendingCount ??
                          _reviewTotalStack;
                });
              },
            ),
          );
        }
        if (_isIntroducing) {
          isFinished.value = true;
          duration.value = 0;
          return;
        }

        duration.value = _secondsFor(kartyProvider.cards.first);
        timeBarResetNotifier.value += 1;

        return;
      }

      if (widget.reviewMode && mounted) {
        setState(() {
          _isReviewEmpty = true;
          // Bekleyen Karty yokken debug kartından açılan ekran, gerçek
          // tamamlanma sonucunu görsel olarak inceletebilsin. Üretimde bu
          // değerler yalnızca sunucunun döndürdüğü sonuçtan gelir.
          if (kDebugMode) {
            _reviewRewardTickets = 1;
          }
        });
        return;
      }

      debugPrint("Karty yüklenirken bir hata oluştu.");
    });
  }

  @override
  void dispose() {
    // Ekrandan çıkarken ses kesiliyor. Servis uygulama ömrü boyunca
    // yaşadığı için bu olmadan oynatıcı arka planda çalmaya devam ediyor ve
    // kullanıcı tekrar girdiğinde bir önceki kartın sesini duyuyordu.
    pronunciationService.stop();
    _boostTimer?.cancel();
    boostProgress.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.reviewMode || _didPrecacheReviewCompleteScene) return;

    _didPrecacheReviewCompleteScene = true;
    precacheImage(
      const AssetImage('assets/scenes/karty_review_complete.png'),
      context,
    );
  }

  void _recordCorrectBoostAnswer() {
    if (widget.reviewMode || _isBoostReady || _isBoostActive) return;

    _boostCharge = (_boostCharge + 1).clamp(0, _boostChargeGoal).toInt();
    if (_boostCharge == _boostChargeGoal) {
      _isBoostReady = true;
    }
  }

  void _recordWrongBoostAnswer() {
    if (widget.reviewMode || _isBoostReady || _isBoostActive) return;
    _boostCharge = 0;
  }

  Future<void> _activateBoost() async {
    if (!_isBoostReady ||
        _isBoostActive ||
        _isBoostActivating ||
        isPaused.value ||
        isFinished.value) {
      return;
    }

    _boostTimer?.cancel();
    setState(() {
      _isBoostReady = false;
      _isBoostActivating = true;
    });
    // Enerji darbesi oynarken cevap kartı ve süre bekler. Böylece efekt bir
    // süs değil, kullanıcının başlattığı boost olayının kendisi olur.
    isPaused.value = true;

    final completed = await _boostActivationKey.currentState?.play();
    if (!mounted || completed != true) return;

    setState(() {
      _isBoostActivating = false;
      _isBoostActive = true;
      _boostCharge = 0;
      _boostRemainingMilliseconds = _boostDurationMilliseconds;
      boostProgress.value = 1;
    });
    isPaused.value = false;

    _boostTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isPaused.value || isFinished.value) return;

      _boostRemainingMilliseconds -= 100;
      boostProgress.value =
          (_boostRemainingMilliseconds / _boostDurationMilliseconds)
              .clamp(0.0, 1.0);

      if (_boostRemainingMilliseconds > 0) return;

      timer.cancel();
      if (!mounted) return;
      setState(() {
        _isBoostActive = false;
        boostProgress.value = 0;
      });
    });
  }

  /// Ekrandaki kartın telaffuzunu çalar: kelimeyle **tanışırken**, dinleme
  /// sorusunda ve cevaptan **sonra**. Harf dizerken duyurmak cevabı sızdırır.
  void _speakCurrentKarty() {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;
    pronunciationService.play(cards.first.audioUrl);
  }

  void _speakCurrentKartySlowly() {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;
    pronunciationService.playSlowly(cards.first.audioUrl);
  }

  /// Cevap sesi kelimenin üstüne binmesin diye telaffuz biraz gecikir.
  void _speakAfterChime() {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _speakCurrentKarty();
    });
  }

  /// Destedeki sıradaki kartların ve seçeneklerin görsellerini önden çözer.
  ///
  /// `Image.file` çözümlemeyi ilk çizimde yapıyor; kart değiştiğinde yeni
  /// görsel birkaç kare geç geliyordu. Önbellek yinelenen istekleri kendisi
  /// eliyor, bu yüzden her `build`'de çağrılması güvenli.
  void _precacheUpcomingCards(KartyProvider cardProvider) {
    for (final (index, card) in cardProvider.cards.indexed) {
      if (index > 0) precacheImage(FileImage(File(card.kartyUrl)), context);
      for (final option in card.options) {
        precacheImage(FileImage(File(option.imagePath)), context);
      }
    }
  }

  /// Tanışma ve dinleme kartı ekrana geldiğinde sesi bir kez çalar.
  ///
  /// Otomatik çalıyor çünkü ilk temasın **duyulması** gerekiyor; kullanıcı
  /// butonu keşfetmeyebilir ve kelimeyi yanlış telaffuzla ezberleyebilir.
  void _autoPlayIfNeeded() {
    if (!_deckReady) return;
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;
    final mode = _modeOf(cards.first);
    if (mode != KartyCardMode.introduce && mode != KartyCardMode.listen) {
      return;
    }
    if (isFinished.value && mode == KartyCardMode.listen) return;

    final kartyId = cards.first.kartyId;
    if (_autoPlayedKartyId == kartyId) return;
    _autoPlayedKartyId = kartyId;

    // Kart yerleşmeden çalmaya başlamak sesi geçişin altında bırakıyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentKarty());
  }

  /// Ekrandaki kart bir **tanışma** kartı mı.
  ///
  /// Kararı sunucu veriyor (`KartyPresentationPolicy`); istemci yalnız
  /// okuyor. Cevap düğmeleri ve zamanlayıcı bu tek kaynağa bakıyor.
  bool get _isIntroducing {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return false;
    return cards.first.mode == KartyCardMode.introduce;
  }

  /// Tanışma kartındaki "Anladım". Kelime kaydedilir ve sıradaki karta
  /// geçilir — **soru hemen sorulmaz**: ekranda duran bir kelimeyi sormak
  /// hafızayı değil kısa süreli belleği ölçer. Kelime sonraki turlarda
  /// soru olarak geri gelir.
  Future<void> _acknowledgeIntroduction(BuildContext context) async {
    final cards = kartyProvider.cards;
    if (cards.isEmpty) return;

    isFinished.value = true;
    await kartyService.recordKartyIntroduction(cards.first.kartyId);
    if (!mounted) return;

    // Desteyi ilerletmenin **tek yolu** bu: önyükleme, görsel kayma ve
    // sonraki kart hep birlikte yürüyor. Ayrı bir ilerletme yazmak ikinci
    // bir akış doğururdu ve biri diğerinden sapardı.
    await _finishAnsweredCard(context);
  }

  /// Ses kapalıyken dinleme sorusu sorulamaz; harf dizmeye düşer.
  KartyCardMode _modeOf(Karty card) =>
      card.mode == KartyCardMode.listen && pronunciationService.isMuted.value
          ? KartyCardMode.arrangeLetters
          : card.mode;

  int _secondsFor(Karty card) => switch (_modeOf(card)) {
        KartyCardMode.listen => 12,
        KartyCardMode.arrangeLetters =>
          math.max(12, 5 + card.correctText.length * 2),
        _ => 10,
      };

  _QuestionAnswer _answerFor(Karty card) {
    final answer = _answer;
    if (answer != null && answer.kartyId == card.kartyId) return answer;
    return _answer = _QuestionAnswer(card.kartyId, card.correctText);
  }

  bool get _questionOpen =>
      !_answerLocked &&
      !_isDeckAdvancing &&
      !_isBoostActivating &&
      !isFinished.value &&
      !isPaused.value &&
      duration.value > 0;

  void _pickOption(Karty card, int optionId) {
    if (!_questionOpen) return;
    setState(() => _answerFor(card).optionId = optionId);
    _submitAnswer(optionId == card.kartyId);
  }

  void _pickArticle(Karty card, String article) {
    if (!_questionOpen) return;
    setState(() => _answerFor(card).article = article);
    _submitAnswer(article == card.article.trim().toLowerCase());
  }

  void _tapLetter(Karty card, int index) {
    if (!_questionOpen) return;
    final answer = _answerFor(card);
    final word = card.correctText;
    if (answer.placed.contains(index) || answer.placed.length >= word.length) {
      return;
    }

    // Kelime bütün yuvalar dolunca bir kerede değerlendirilir; o ana kadar
    // yanlış konmuş harf yuvasına dokunularak geri alınır. Son yuvaya konan
    // harf havuzda kalan tek harf olduğu için ayrı bir kontrol düğmesi yok.
    // Yazılış karşılaştırıldığı için aynı harften ikisi birbirinin yerine
    // geçer.
    HapticFeedback.selectionClick();
    final complete = answer.placed.length + 1 == word.length;
    setState(() {
      answer.placed.add(index);
      if (complete) answer.lettersFailed = answer.spelled != word;
    });
    if (complete) _submitAnswer(!answer.lettersFailed);
  }

  void _removeLetter(Karty card, int slot) {
    if (!_questionOpen) return;
    final answer = _answerFor(card);
    if (slot >= answer.placed.length) return;
    HapticFeedback.selectionClick();
    setState(() => answer.placed.removeAt(slot));
  }

  Future<void> _answerQuestion(
    BuildContext context,
    bool isCorrectAnswer,
  ) async {
    isFinished.value = true; // TimeBar'ı durdurduk
    final currentKarty = kartyProvider.cards[0];

    // Sonuç dokunduğu anda okunur, ağı beklemez. Telaffuz yanlışta da
    // duyulur: hatanın düzeltilmesi en çok burada işe yarıyor.
    final verdict =
        isCorrectAnswer ? isTrueAnswerBlurActive : isFalseAnswerBlurActive;
    verdict.value = true;
    isCorrectAnswer ? gameFeedback.correct() : gameFeedback.wrong();
    _speakAfterChime();

    if (widget.reviewMode) {
      final reviewResult = await kartyService.resolveWrongKartyReview(
        currentKarty.kartyId,
        isCorrectAnswer,
      );
      if (!mounted) return;
      _prefetchNext();
      unawaited(
        profileLearningStatsProvider.refreshFromService(userService),
      );

      if (isCorrectAnswer) {
        setState(() {
          streak += 1;
          if (_reviewTotalStack > 0) {
            _reviewCompletedStack =
                (_reviewCompletedStack + 1).clamp(0, _reviewTotalStack).toInt();
          }
          _reviewRewardTickets += reviewResult?.rewardTickets ?? 0;
          duration.value = 0;
        });

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: 0,
          isReviewMode: true,
        );
        await Future.delayed(Duration(seconds: 1));
        if (!mounted) return;

        isTrueAnswerBlurActive.value = false;
        await Future.delayed(Duration(milliseconds: 600));
        if (!mounted) return;

        timeBarResetNotifier.value += 1;

        return;
      }

      setState(() {
        streak = 0;
        duration.value = 0;
      });

      await Future.delayed(Duration(milliseconds: 2000));
      if (!mounted) return;

      isFalseAnswerBlurActive.value = false;
      await Future.delayed(Duration(milliseconds: 600));
      if (!mounted) return;

      timeBarResetNotifier.value += 1;

      return;
    }

    // Kupa arttı
    if (isCorrectAnswer) {
      // Kutlamada gösterilen **ödül**. Sunucuya gönderilen sayı bu değil:
      // yön ve çarpan ayrı gidiyor, çünkü boost ödülü (görünen puan, lig
      // puanı) çarparken gizli zorluk termostatına dokunmuyor. Tek sayı
      // gönderildiği dönemde boost zorluğu da üçe katlıyordu.
      final awardedPoints = _isBoostActive ? 3 : 1;
      final minimumFeedbackTime =
          Future.delayed(const Duration(milliseconds: 850));
      var apiResponse = await userService.updateScoreById(
        1,
        kartyId: currentKarty.kartyId,
        boostActive: _isBoostActive,
      );
      if (!mounted) return;
      verdict.value = apiResponse.errorCode == null;
      if (apiResponse.errorCode == null) {
        _sessionPoints += awardedPoints;
        _sessionCorrect += 1;
        _countAnswer(currentKarty);
        setState(() {
          streak += 1;
          _recordCorrectBoostAnswer();
          duration.value = 0; // Süreyi tekrar ayarla
        });
        _prefetchNext();

        // Sunucudan yenilenmiş lig sayısını beklerken kullanıcıyı cevapsız
        // bırakmıyoruz: yeşil bant ve kelime çoktan yanıyor.
        await userService.scoreWithLivesById(context);
        if (!mounted) return;
        profileLearningStatsProvider.prefetchForHome(userService);

        _successCelebrationKey.currentState?.play(
          streak: streak,
          awardedPoints: awardedPoints,
        );
        await Future.wait([
          minimumFeedbackTime,
          Future.delayed(const Duration(milliseconds: 260)),
        ]);
        if (!mounted) return;

        isTrueAnswerBlurActive.value = false;
        await Future.delayed(const Duration(milliseconds: 520));
        if (!mounted) return;

        timeBarResetNotifier.value += 1; // ProgressBar'ı sıfırla
      }

      return;
    }

    // Kupa düştü
    final minimumFeedbackTime =
        Future.delayed(const Duration(milliseconds: 1400));
    var apiResponse =
        await userService.updateScoreById(-1, kartyId: currentKarty.kartyId);
    if (!mounted) return;
    verdict.value = apiResponse.errorCode == null;
    if (apiResponse.errorCode == null) {
      _sessionWrongIds.add(currentKarty.kartyId);
      _countAnswer(currentKarty);
      setState(() {
        streak = 0;
        _recordWrongBoostAnswer();
        duration.value = 0; // Süreyi tekrar ayarla
      });
      _prefetchNext();

      await userService.scoreWithLivesById(context);
      if (!mounted) return;
      profileLearningStatsProvider.prefetchForHome(userService);

      await minimumFeedbackTime;
      if (!mounted) return;

      isFalseAnswerBlurActive.value = false;
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;

      timeBarResetNotifier.value += 1; // ProgressBar'ı sıfırla
    }
  }

  /// Sıradaki kart sonuç ekrandayken iner. Cevap sayıldıktan sonra istenir:
  /// sunucu bu cevabı da hesaba katsın.
  void _prefetchNext() => kartyProvider.prefetchNextKarty(
        context,
        reviewMode: widget.reviewMode,
      );

  void _countAnswer(Karty karty) {
    _sessionAnswered += 1;
    kartyProvider.recordAnswered(karty);
    _sessionWords[karty.kartyId] = KartyWord(
      word: karty.correctText,
      article: karty.article,
      image: FileImage(File(karty.kartyUrl)),
      box: 1,
    );
  }

  /// Karty Yolu oyununda destenin bitip bitmediğini sunucuya sorar
  /// (`karty/session`); bittiyse özeti gösterir. Pratikte sunucuya
  /// sorulmaz: tur [_practiceRound] cevapla biter. Özetten patikaya
  /// dönülürse oyun kapanır ve `true` döner; PRATİK YAP'ta aynı oturum
  /// pratik turuyla sürer. Ağ hatası oyunu durdurmaz: bitiş bir sonraki
  /// cevapta sorulur.
  Future<bool> _finishSessionIfDone() async {
    final session = widget.session;
    if (session == null || widget.reviewMode) return false;
    if (_practicing) {
      if (_sessionAnswered < _practiceRound) return false;
      return _presentSummary(_buildPracticeSummary(session));
    }

    KartySessionStatusResponse? status;
    try {
      final response = await kartyService.sessionStatus(
        unit: session.unit.number,
        deck: session.deck,
        reviews: kartyProvider.reviewsAnswered,
      );
      status = response.errorCode == null ? response.data : null;
    } catch (_) {
      status = null;
    }
    if (!mounted || status == null || !status.complete) return false;
    return _presentSummary(_buildSummary(session, status));
  }

  /// Özeti açar; DEVAM ET'te oyun kapanır (`true`), PRATİK YAP ya da BİR TUR
  /// DAHA'da yeni bir pratik turu başlar.
  Future<bool> _presentSummary(KartySessionSummary summary) async {
    await Future.wait([
      for (final word in summary.words.take(8))
        precacheImage(word.image, context, onError: (_, __) {}),
      if (summary.unit.emblem != null)
        precacheImage(summary.unit.emblem!, context, onError: (_, __) {}),
    ]).timeout(const Duration(milliseconds: 1500), onTimeout: () => []);
    if (!mounted) return false;

    gameFeedback.complete();
    final choice = await Navigator.of(context).push<KartySummaryChoice>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) =>
            KartySessionSummaryScreen(summary: summary),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
    if (!mounted) return true;
    if (choice == KartySummaryChoice.practice) {
      _practicing = true;
      _startPracticeRound();
      return false;
    }
    await _closeKartyScreen();
    return true;
  }

  /// Yeni pratik turu: özetteki sayılar yalnız bu turu anlatsın.
  void _startPracticeRound() {
    _sessionPoints = 0;
    _sessionCorrect = 0;
    _sessionAnswered = 0;
    _sessionWrongIds.clear();
    _sessionWords.clear();
  }

  KartySessionSummary _buildSummary(
    KartySessionArgs session,
    KartySessionStatusResponse status,
  ) {
    final before = session.unit;
    final unit = _unitNow = KartyUnit(
      number: before.number,
      title: before.title,
      state: before.state,
      wordCount: status.unitWordCount,
      consolidatedCount: status.unitConsolidated,
      unlockGoal: before.unlockGoal,
      emblem: before.emblem,
    );
    return KartySessionSummary(
      unit: unit,
      deck: session.deck,
      words: session.deck != null
          ? [
              for (final word in status.words)
                KartyWord(
                  word: word.nounText,
                  article: word.article,
                  image: CachedSignedImage(word.kartyUrl),
                  box: word.box,
                ),
            ]
          : _sessionWords.values.toList(),
      newCount: session.deck != null ? status.deckSize : 0,
      reviewCount: kartyProvider.reviewsAnswered,
      consolidatedBefore: before.consolidatedCount,
      points: _sessionPoints,
      correct: _sessionCorrect,
      answered: _sessionAnswered,
      revenge: _sessionWrongIds.length,
      league: _leagueNote(),
    );
  }

  /// Pratik turunun özeti. Pratik kutu ilerletmez: ünite çubuğu turda
  /// kıpırdamaz, bilinen son hâliyle çizilir.
  KartySessionSummary _buildPracticeSummary(KartySessionArgs session) {
    final unit = _unitNow ?? session.unit;
    return KartySessionSummary(
      unit: unit,
      practice: true,
      words: _sessionWords.values.toList(),
      newCount: 0,
      reviewCount: 0,
      consolidatedBefore: unit.consolidatedCount,
      points: _sessionPoints,
      correct: _sessionCorrect,
      answered: _sessionAnswered,
      revenge: _sessionWrongIds.length,
      league: _leagueNote(),
    );
  }

  /// Lig satırı yalnız sıradaki lige yaklaşıldığında (10 puan ve altı):
  /// her özette görünen bir hatırlatma birkaç oyunda görünmez olurdu.
  KartyLeagueNote? _leagueNote() {
    final league =
        context.read<ScoreWithLivesProvider>().scoreWithLives?.league;
    final left = league?.pointsToNextLeague;
    if (league == null || left == null || left <= 0 || left > 10) return null;
    if (league.rank < 1 || league.rank >= LeagueVisuals.order.length) {
      return null;
    }
    final next = LeagueVisuals.order[league.rank];
    return KartyLeagueNote(
      nextLeagueKey: next,
      nextLeagueName: LeagueVisuals.names[next] ?? '',
      pointsLeft: left,
    );
  }

  Future<void> _nextKarty(BuildContext context) async {
    bool isLoaded = await kartyProvider.loadKarty(
      context,
      reviewMode: widget.reviewMode,
    );
    if (isLoaded) {
      // Tanışma kartında **süre işlemez**. Okumak için gelen bir kartta geri
      // sayım öğrenmeyi aceleye getirir; kullanıcı kelimeye bakmak yerine
      // butona yetişmeye çalışır.
      if (_isIntroducing) {
        isFinished.value = true;
        duration.value = 0;
        return;
      }

      duration.value = _secondsFor(kartyProvider.cards.first);

      await Future.delayed(Duration(milliseconds: 20));
      timeBarResetNotifier.value += 1;
      isFinished.value = false; // TimeBar'ı başlattık

      return;
    }

    if (widget.reviewMode && mounted) {
      setState(() {
        if (_reviewTotalStack > 0) {
          _reviewCompletedStack = _reviewTotalStack;
        }
        _isReviewEmpty = true;
      });
      isFinished.value = true;
      gameFeedback.complete();
      return;
    }

    AppNotifier.showMessage("Karty yüklenirken bir hata oluştu.");
  }

  void _restartCurrentKarty() {
    _boostTimer?.cancel();
    _boostActivationKey.currentState?.stop();
    _boostCharge = 0;
    _isBoostReady = false;
    _isBoostActive = false;
    _isBoostActivating = false;
    _boostRemainingMilliseconds = 0;
    boostProgress.value = 0;

    _resetCard();
    isPaused.value = false;
    isFinished.value = false;
    duration.value = _secondsFor(kartyProvider.cards.first);
    timeBarResetNotifier.value += 1;
    _autoPlayedKartyId = null;
  }

  Future<void> _closeKartyScreen() async {
    _successCelebrationKey.currentState?.stop();
    _boostActivationKey.currentState?.stop();
    if (isPaused.value) {
      isPaused.value = false;
      await Future.delayed(const Duration(milliseconds: 16));
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _resetCard() {
    setState(() {
      _answer = null;
      _answerLocked = false;
      _isDeckAdvancing = false;
      _fadeBody = false;
    });
  }

  /// Tam boy kartlar birbirine kayar; ızgara ve küçük kart düzeni kaymaz.
  bool _usesFullDeck(Karty card) => switch (_modeOf(card)) {
        KartyCardMode.introduce || KartyCardMode.pickArticle => true,
        _ => false,
      };

  Future<void> _advanceDeckVisual() async {
    // Oyun ilk kartla açılıyor; geçişin biçimi sıradaki karta bağlı.
    await kartyProvider.whenQueueFilled();
    if (!mounted) return;

    // Gövde sönecekse sıradaki kart hazır olsun: ekran boş beklemesin.
    final fade = !kartyProvider.cards.take(2).every(_usesFullDeck);
    if (fade) await kartyProvider.whenPrefetched();
    if (!mounted) return;

    setState(() {
      _isDeckAdvancing = true;
      _fadeBody = fade;
    });

    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _finishAnsweredCard(BuildContext context) async {
    if (!mounted) return;
    kartyProvider.prefetchNextKarty(
      context,
      reviewMode: widget.reviewMode,
    );
    await _advanceDeckVisual();
    if (!mounted) return;
    await _nextKarty(context);
    if (!mounted) return;

    _resetCard();
  }

  /// Bütün soru tiplerinin tek cevap girişi.
  Future<void> _submitAnswer(bool isCorrectAnswer) async {
    if (_answerLocked) return;
    duration.value = 0;
    _answerLocked = true;

    try {
      await _answerQuestion(context, isCorrectAnswer);
      if (await _finishSessionIfDone()) return;
      await _finishAnsweredCard(context);
    } catch (_) {
      if (!mounted) return;

      isTrueAnswerBlurActive.value = false;
      isFalseAnswerBlurActive.value = false;
      _resetCard();
      duration.value = _secondsFor(kartyProvider.cards.first);
      isFinished.value = false;
      timeBarResetNotifier.value += 1;
      AppNotifier.showMessage("Bir hata oluştu. Tekrar deneyin.");
    }
  }

  /// Test kolaylığı: sorunun doğru cevabını normal cevap akışına verir.
  /// Puan ve boost doğrudan artırılmaz; sunucu ve animasyonlar aynen çalışır.
  Future<void> _debugAnswerCorrectly() async {
    if (!kDebugMode || !_questionOpen || _isIntroducing) return;
    if (kartyProvider.cards.isEmpty) return;

    final card = kartyProvider.cards.first;
    final answer = _answerFor(card);
    setState(() {
      answer.optionId = card.kartyId;
      answer.article = card.article.trim().toLowerCase();
      answer.placed
        ..clear()
        ..addAll(answer.solutionFor(card.correctText));
    });
    await _submitAnswer(true);
  }

  void _togglePauseMenu() {
    if (_isBoostActivating || _isDeckAdvancing || _answerLocked) return;
    final opening = !_pauseMenuOpen;
    if (opening) {
      pronunciationService.stop();
      _successCelebrationKey.currentState?.stop();
    }
    setState(() => _pauseMenuOpen = opening);
    isPaused.value = opening;
  }

  String _promptFor(KartyCardMode mode) => switch (mode) {
        KartyCardMode.introduce => 'Yeni kelime',
        KartyCardMode.pickImage => 'Görseli bul',
        KartyCardMode.pickArticle => 'Artikeli seç',
        KartyCardMode.arrangeLetters => 'Harfleri diz',
        KartyCardMode.listen => 'Duyduğunu bul',
      };

  /// Kartın üstündeki satır: soru cevabı sızdırmayacak biçimde sorulur.
  Widget? _titleFor(Karty card, KartyCardMode mode, double scale) {
    final answer = _answerFor(card);
    Widget word({String? article}) => KartyFeedbackWord(
          article: article ?? card.article,
          text: card.correctText,
          scale: scale,
          isCorrectActive: isTrueAnswerBlurActive,
          isWrongActive: isFalseAnswerBlurActive,
        );

    switch (mode) {
      case KartyCardMode.introduce:
      case KartyCardMode.pickImage:
      case KartyCardMode.listen:
        return null;
      case KartyCardMode.pickArticle:
        return word(
            article: answer.article == null ? kartyUnknownArticle : null);
      case KartyCardMode.arrangeLetters:
        return KartyLetterSlots(
          scale: scale,
          article: card.article,
          word: card.correctText,
          placed: [for (final index in answer.placed) answer.tiles[index]],
          state: answer.lettersFailed
              ? KartyLettersState.failed
              : answer.placed.length == card.correctText.length
                  ? KartyLettersState.solved
                  : KartyLettersState.answering,
          // Süre dolunca ya da duraklatılınca yuvalar düğme gibi davranmaz.
          onRemove: _questionOpen ? (slot) => _removeLetter(card, slot) : null,
        );
    }
  }

  /// Görsel seçilen sorular: soru kartı ve altında dört görsel düğmesi.
  bool _isImageChoice(Karty card) => switch (_modeOf(card)) {
        KartyCardMode.pickImage || KartyCardMode.listen => true,
        _ => false,
      };

  Widget _timedOutFace(double scale) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            HourglassMark(size: 84 * scale),
            SizedBox(width: 20 * scale),
            Text(
              'Süre doldu',
              style: TextStyle(
                color: const Color(0xFFE9EEF5),
                fontFamily: AppTypography.displayFamily,
                fontSize: 48 * scale,
                fontWeight: AppTypography.heading,
              ),
            ),
          ]),
          SizedBox(height: 24 * scale),
          // Alt yuvada görsel düğmeleri durduğu için yeniden deneme kartta.
          DepthPressableButton(
            text: 'TEKRAR DENE',
            width: 260 * scale,
            height: 86 * scale,
            radius: 24 * scale,
            shadowOffset: 10 * scale,
            backgroundColor: const Color(0xFF1CB1F5),
            shadowColor: const Color(0xFF1B84B5),
            fontSize: 26 * scale,
            onPressed: _restartCurrentKarty,
          ),
        ],
      );

  Widget _deck(
    Karty card,
    KartyCardLayout layout, {
    required Widget? title,
    required bool introducing,
    required bool timedOut,
  }) =>
      SwipableCard(
        karty: card,
        layout: layout,
        showInlineRestartAction: false,
        title: title,
        onPronounce: introducing && card.audioUrl?.isNotEmpty == true
            ? _speakCurrentKarty
            : null,
        showRestartState: timedOut,
        isAdvancingDeck: _isDeckAdvancing && !_fadeBody,
        boostEnabled: !widget.reviewMode && !introducing,
        boostCharge: _boostCharge,
        boostChargeGoal: _boostChargeGoal,
        isBoostReady: _isBoostReady,
        isBoostActive: _isBoostActive && !timedOut,
        isBoostActivating: _isBoostActivating,
        topLeftBoostAnchorKey: _boostTopLeftAnchorKey,
        bottomRightBoostAnchorKey: _boostBottomRightAnchorKey,
        boostProgress: boostProgress,
        onRestart: _restartCurrentKarty,
        onBoostTap: _activateBoost,
        isTrueAnswerBlurActive: isTrueAnswerBlurActive,
        isFalseAnswerBlurActive: isFalseAnswerBlurActive,
      );

  /// Görsel seçilen sorular: soru yatay kartta, şimşekler onun köşesinde;
  /// dört görsel kartın altında düğme olur. Artikel ve harf sorularıyla aynı
  /// kural: kart soruyu taşır, cevaplar altındadır.
  Widget _imageGrid(
    Karty card,
    KartyCardMode mode,
    KartyCardLayout layout,
    double scale, {
    required bool canAnswer,
    required bool timedOut,
  }) {
    final answer = _answerFor(card);
    final gap = 34 * scale;
    // Bu soruda alt yuva boş: düğmeler onun yerini de kullanır.
    final room = layout.titleToCardGap +
        layout.size.height +
        2 * layout.layerOffset +
        171 * scale -
        KartyQuestionCard.extentFor(scale) -
        gap;
    final tileHeight =
        math.min(322 * scale, (room - 26 * scale - 24 * scale) / 2);

    final Widget question;
    if (timedOut) {
      question = _timedOutFace(scale);
    } else if (mode == KartyCardMode.listen && answer.optionId == null) {
      question = KartyListenPlayer(
        scale: scale,
        onListen: _speakCurrentKarty,
        onListenSlowly: _speakCurrentKartySlowly,
      );
    } else {
      question = KartyFeedbackWord(
        article: card.article,
        text: card.correctText,
        scale: scale,
        isCorrectActive: isTrueAnswerBlurActive,
        isWrongActive: isFalseAnswerBlurActive,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KartyQuestionCard(
          scale: scale,
          width: layout.size.width,
          isCorrectActive: isTrueAnswerBlurActive,
          isWrongActive: isFalseAnswerBlurActive,
          dimmed: timedOut,
          boostMeter: widget.reviewMode
              ? null
              : KartyBoostEdgeMeter(
                  scale: scale,
                  boltScale: 100 / 127.5,
                  charge: timedOut ? 0 : _boostCharge,
                  chargeGoal: _boostChargeGoal,
                  isReady: _isBoostReady && !timedOut,
                  isActive: _isBoostActive && !timedOut,
                  isActivating: _isBoostActivating,
                  boostProgress: boostProgress,
                  onTap: _activateBoost,
                  interactive: !timedOut,
                  topLeftAnchorKey: timedOut ? null : _boostTopLeftAnchorKey,
                  bottomRightAnchorKey:
                      timedOut ? null : _boostBottomRightAnchorKey,
                ),
          child: question,
        ),
        SizedBox(height: gap),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: timedOut ? .42 : 1,
          child: IgnorePointer(
            ignoring: timedOut,
            child: KartyImageOptions(
              scale: scale,
              width: layout.size.width,
              tileHeight: tileHeight,
              answerId: card.kartyId,
              pickedId: answer.optionId,
              enabled: canAnswer,
              options: [
                for (final option in card.options)
                  KartyImageOption(
                    kartyId: option.kartyId,
                    image: FileImage(File(option.imagePath)),
                  ),
              ],
              onPick: (optionId) => _pickOption(card, optionId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionBody(
    Karty card,
    KartyCardLayout layout,
    double scale, {
    required bool introducing,
    required bool timedOut,
    required bool canAnswer,
  }) {
    final mode = _modeOf(card);
    if (_isImageChoice(card)) {
      return _imageGrid(
        card,
        mode,
        layout,
        scale,
        canAnswer: canAnswer,
        timedOut: timedOut,
      );
    }

    final title = _titleFor(card, mode, scale);
    if (mode != KartyCardMode.arrangeLetters) {
      return _deck(
        card,
        layout,
        title: title,
        introducing: introducing,
        timedOut: timedOut,
      );
    }

    final answer = _answerFor(card);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _deck(
          card,
          KartyCardLayout(
            size: Size(layout.size.width * .84, layout.size.height * .78),
            titleToCardGap: layout.titleToCardGap,
            layerOffset: layout.layerOffset,
            borderWidth: layout.borderWidth,
          ),
          title: title,
          introducing: false,
          timedOut: timedOut,
        ),
        // Süre dolunca altta TEKRAR DENE çıkıyor; harfler ona binmesin.
        if (!timedOut &&
            !answer.lettersFailed &&
            answer.placed.length < card.correctText.length) ...[
          SizedBox(height: 50 * scale),
          KartyLetterTiles(
            scale: scale,
            width: 690 * scale,
            letters: answer.tiles,
            used: answer.placed.toSet(),
            enabled: canAnswer,
            onTap: (index) => _tapLetter(card, index),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = Provider.of<KartyProvider>(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth / 750;
    _autoPlayIfNeeded();
    _precacheUpcomingCards(cardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            reverseDuration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild
              ],
            ),
            transitionBuilder: (child, animation) {
              final fade = FadeTransition(opacity: animation, child: child);
              if (child.key != const ValueKey('review-complete-surface')) {
                return fade;
              }
              return SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, .025), end: Offset.zero)
                    .animate(animation),
                child: fade,
              );
            },
            child: _isReviewEmpty
                ? KeyedSubtree(
                    key: const ValueKey('review-complete-surface'),
                    child: KartyReviewCompleteState(
                      scale: scale,
                      rewardTickets: _reviewRewardTickets,
                      onClose: _closeKartyScreen,
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('quiz-active-surface'),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isFinished,
                      builder: (context, finished, _) =>
                          ValueListenableBuilder<bool>(
                        valueListenable: isPaused,
                        builder: (context, paused, _) {
                          final loaded = cardProvider.isLoaded &&
                              cardProvider.cards.isNotEmpty;
                          final introducing = loaded && _isIntroducing;
                          final timedOut = loaded &&
                              finished &&
                              !introducing &&
                              !_isDeckAdvancing &&
                              !_answerLocked;
                          final busy = _isDeckAdvancing ||
                              _answerLocked ||
                              _isBoostActivating;
                          final canAnswer = loaded && _questionOpen;
                          final card = loaded ? cardProvider.cards.first : null;
                          final fadeOpacity = _fadeBody ? 0.0 : 1.0;
                          const fadeDuration = Duration(milliseconds: 200);
                          return KartyPlaySurface(
                            prompt: card == null || timedOut
                                ? null
                                : _promptFor(_modeOf(card)),
                            promptVisible: !_fadeBody,
                            header: ValueListenableBuilder<bool>(
                              valueListenable: pronunciationService.isMuted,
                              builder: (context, muted, _) =>
                                  ValueListenableBuilder<bool>(
                                valueListenable:
                                    pronunciationService.isSpeaking,
                                builder: (context, speaking, _) => KartyTopBar(
                                  scale: scale,
                                  duration: duration,
                                  timeBarResetNotifier: timeBarResetNotifier,
                                  isFinished: isFinished,
                                  isPaused: isPaused,
                                  isBoostActive: _isBoostActive,
                                  isIntroducing: introducing,
                                  reviewMode: widget.reviewMode,
                                  reviewTotalStack: _reviewTotalStack,
                                  reviewCompletedStack: _reviewCompletedStack,
                                  leaguePointsAnchorKey: _boostLeagueTargetKey,
                                  muted: muted,
                                  onToggleSound: () {
                                    pronunciationService.setMuted(!muted);
                                    // Dinleme sorusu sesle var oluyor.
                                    setState(() {});
                                  },
                                  pauseEnabled: !busy,
                                  pauseMenuOpen: _pauseMenuOpen,
                                  speaking: speaking,
                                  onPause: _togglePauseMenu,
                                ),
                              ),
                            ),
                            cardBuilder: (layout) {
                              if (!loaded) {
                                return SkeletonReveal(
                                  child: KartyDeckSkeleton(layout: layout),
                                );
                              }
                              return AnimatedOpacity(
                                duration: fadeDuration,
                                opacity: fadeOpacity,
                                child: _questionBody(
                                  card!,
                                  layout,
                                  scale,
                                  introducing: introducing,
                                  timedOut: timedOut,
                                  canAnswer: canAnswer,
                                ),
                              );
                            },
                            actions: !loaded || _isImageChoice(card!)
                                ? const SizedBox.shrink()
                                : AnimatedOpacity(
                                    duration: fadeDuration,
                                    opacity: fadeOpacity,
                                    child: KartyAnswerActions(
                                      scale: scale,
                                      isIntroducing: introducing,
                                      isTimedOut: timedOut,
                                      enabled: !paused &&
                                          !busy &&
                                          (introducing ||
                                              timedOut ||
                                              canAnswer),
                                      answers: _modeOf(card) ==
                                              KartyCardMode.pickArticle
                                          ? KartyArticleChoices(
                                              scale: scale,
                                              enabled: canAnswer,
                                              revealed:
                                                  _answerFor(card).article ==
                                                          null
                                                      ? null
                                                      : card.article
                                                          .trim()
                                                          .toLowerCase(),
                                              onPick: (article) =>
                                                  _pickArticle(card, article),
                                            )
                                          : null,
                                      onContinue: () {
                                        if (introducing) {
                                          _acknowledgeIntroduction(context);
                                        } else {
                                          _restartCurrentKarty();
                                        }
                                      },
                                    ),
                                  ),
                            // Sadece debug sürümünde; ana cevaplarla aynı ağırlıkta değil.
                            debugAction: kDebugMode &&
                                    loaded &&
                                    !introducing &&
                                    !timedOut
                                ? TextButton(
                                    onPressed: canAnswer
                                        ? _debugAnswerCorrectly
                                        : null,
                                    style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF8FA0B5)),
                                    child: KartyDebugAnswerLabel(scale: scale),
                                  )
                                : null,
                            overlays: [
                              if (loaded)
                                KartySuccessCelebration(
                                  key: _successCelebrationKey,
                                  scale: scale,
                                  sourceKey: _boostBottomRightAnchorKey,
                                  targetKey: _boostLeagueTargetKey,
                                ),
                              KartyBoostActivationEffect(
                                key: _boostActivationKey,
                                scale: scale,
                                topLeftSourceKey: _boostTopLeftAnchorKey,
                                bottomRightSourceKey:
                                    _boostBottomRightAnchorKey,
                                targetKey: _boostLeagueTargetKey,
                              ),
                              // Efekt de süreyi durdurur; menü yalnız kullanıcının
                              // duraklatma eylemiyle açılır.
                              if (_pauseMenuOpen)
                                KartyPauseOverlay(
                                  scale: scale,
                                  streak: streak,
                                  onResume: _togglePauseMenu,
                                  onExit: _closeKartyScreen,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ));
  }
}
