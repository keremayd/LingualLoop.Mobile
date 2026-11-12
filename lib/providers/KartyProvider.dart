import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';

class KartyProvider with ChangeNotifier {
  final List<Karty> _cards = [];
  bool _isLoaded = false;
  Future<Karty?>? _prefetchFuture;
  bool? _prefetchReviewMode;

  /// Oyunun destesi (Karty Yolu'ndaki şu anki deste). Yeni kelime yalnız
  /// buradan istenir; oyun açılırken [startSession] ile kurulur.
  int? _sessionUnit;
  int? _sessionDeck;

  /// Bilet sahnesi sürerken başlayan ilk yükleme ve ait olduğu deste.
  Future<bool>? _preparedLoad;
  int? _preparedUnit;
  int? _preparedDeck;

  /// [reset] ile artar: sıfırlanmış oyunun bekleyen yüklemesi yeni oyuna
  /// kart karıştırmasın.
  int _generation = 0;

  /// Oyun ilk kartla açılır; destenin kalanı arkada iner. Sıradaki kartı
  /// isteyen her yol önce bunu bekler: kuyruk eksikken sunucuya bildirilen
  /// tekrar sayısı eksik çıkardı.
  Future<void>? _fillFuture;

  /// Oyunda cevaplanan tekrar kartı sayısı. Sunucu tekrarı oyunun payı kadar
  /// verir; ona bildirilen "verilen tekrar" bu sayı ile kuyrukta bekleyen
  /// tekrarlardan türetilir. Ayrı bir sayaç tutulsaydı kuyruktan elenen bir
  /// kart sayıda kalır, sunucu payı doldu sanıp tekrarı keser ve oyun
  /// bitişe hiç varamazdı.
  int _reviewsAnswered = 0;
  int get reviewsAnswered => _reviewsAnswered;

  void startSession({int? unit, int? deck}) {
    _sessionUnit = unit;
    _sessionDeck = deck;
    _reviewsAnswered = 0;
  }

  /// Kartlar bilet sahnesi sürerken inmeye başlar; oyun yükleniyor simgesi
  /// göstermeden açılsın.
  void prepareSession(BuildContext context, {int? unit, int? deck}) {
    reset();
    startSession(unit: unit, deck: deck);
    _preparedUnit = unit;
    _preparedDeck = deck;
    _preparedLoad = loadKarty(context);
  }

  /// Bu deste için hazırlanmış yükleme varsa bir kez teslim eder.
  Future<bool>? takePreparedLoad({int? unit, int? deck}) {
    final load = _preparedLoad;
    if (load == null || unit != _preparedUnit || deck != _preparedDeck) {
      return null;
    }
    _preparedLoad = null;
    return load;
  }

  /// Sunucunun kaydettiği cevap; tekrar kartıysa oyunun tekrar sayısına girer.
  void recordAnswered(Karty card) {
    if (card.stage == KartyCardStage.review) _reviewsAnswered += 1;
  }

  List<Karty> get cards =>
      List.unmodifiable(_cards); // Dışarıdan değiştirilemez liste
  bool get isLoaded => _isLoaded;

  Future<bool> loadKarty(BuildContext context,
      {bool reviewMode = false}) async {
    final kartyService = Provider.of<KartyService>(context, listen: false);
    final localFileService =
        Provider.of<LocalFileService>(context, listen: false);

    if (_cards.isEmpty) {
      _isLoaded = false;
      notifyListeners();

      // Üç kart sırayla, her biri görselleriyle beklenince oyun yükleniyor
      // ekranında kalıyordu; ilk kart yetiyor.
      final generation = _generation;
      final card = await _fetchUniqueKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
      );
      if (generation != _generation) return false;
      if (card == null) {
        notifyListeners();
        return false;
      }

      _cards.add(card);
      _fillFuture = _fillQueue(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
        generation: generation,
      );
      return _completeLoad();
    }

    await _fillFuture;
    final nextCards = _cards.skip(1).toList();
    final prefetchedCard = await _consumePrefetchedCard(reviewMode: reviewMode);
    if (prefetchedCard != null &&
        !nextCards.any((item) => item.kartyId == prefetchedCard.kartyId)) {
      nextCards.add(prefetchedCard);
    }

    while (nextCards.length < 3) {
      final card = await _fetchUniqueKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
        queuedCards: nextCards,
      );
      if (card == null) {
        _cards
          ..clear()
          ..addAll(nextCards);
        _isLoaded = _cards.isNotEmpty;
        notifyListeners();
        return _cards.isNotEmpty;
      }

      nextCards.add(card);
    }

    while (nextCards.length > 3) {
      nextCards.removeLast();
    }

    _cards
      ..clear()
      ..addAll(nextCards);

    return _completeLoad();
  }

  /// İlk yüklemenin kalanı: deste üç karta tamamlanır, her kart inince
  /// ekran sıradaki görselleri önden çözebilsin diye haber verilir.
  Future<void> _fillQueue(
    KartyService kartyService,
    LocalFileService localFileService, {
    required bool reviewMode,
    required int generation,
  }) async {
    while (_cards.length < 3) {
      final card = await _fetchUniqueKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
      );
      if (generation != _generation || card == null) return;
      _cards.add(card);
      notifyListeners();
    }
  }

  void prefetchNextKarty(BuildContext context, {required bool reviewMode}) {
    if (_prefetchFuture != null && _prefetchReviewMode == reviewMode) {
      return;
    }

    final kartyService = Provider.of<KartyService>(context, listen: false);
    final localFileService =
        Provider.of<LocalFileService>(context, listen: false);
    final fill = _fillFuture;

    _prefetchReviewMode = reviewMode;
    _prefetchFuture = () async {
      await fill;
      return _fetchUniqueKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
        queuedCards: _cards.skip(1).toList(),
      );
    }();
  }

  /// Sıradaki kart inene kadar bekler; hata olursa da döner.
  Future<void> whenPrefetched() async {
    await _prefetchFuture;
  }

  /// Destenin ilk yüklemesi arkada tamamlanana kadar bekler.
  Future<void> whenQueueFilled() async {
    await _fillFuture;
  }

  Future<Karty?> _fetchUniqueKarty(
    KartyService kartyService,
    LocalFileService localFileService, {
    required bool reviewMode,
    List<Karty>? queuedCards,
  }) async {
    final cardsToCheck = queuedCards ?? _cards;

    final reviewsServed = _reviewsAnswered +
        cardsToCheck
            .where((item) => item.stage == KartyCardStage.review)
            .length;
    for (var attempt = 0; attempt < 5; attempt++) {
      final card = await _fetchKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
        reviewsServed: reviewsServed,
      );

      if (card == null) {
        return null;
      }

      final alreadyQueued =
          cardsToCheck.any((item) => item.kartyId == card.kartyId);
      if (!alreadyQueued) {
        return card;
      }
    }

    return null;
  }

  Future<Karty?> _fetchKarty(
      KartyService kartyService, LocalFileService localFileService,
      {required bool reviewMode, required int reviewsServed}) async {
    try {
      final apiResponse = reviewMode
          ? await kartyService.randomWrong()
          : await kartyService.random(
              unit: _sessionUnit,
              deck: _sessionDeck,
              reviews: _sessionUnit == null ? null : reviewsServed,
            );
      if (apiResponse.errorCode != null || apiResponse.data == null) {
        return null;
      }

      // Gelen signedUrl'deki karty görselini cache'e aktarıyoruz
      final cacheUrl = await localFileService.cacheKartyImage(
        apiResponse.data!.kartyUrl,
        apiResponse.data!.kartyId,
      );

      // Seçenek görselleri de soru ekrana gelmeden iner.
      final options = await Future.wait(apiResponse.data!.options.map(
        (option) async => KartyOption(
          kartyId: option.kartyId,
          imagePath: await localFileService.cacheKartyImage(option.kartyUrl, option.kartyId),
        ),
      ));

      // Cache'teki kaydettiğimiz adres üzerinden ilerletiyoruz
      return Karty(
        kartyId: apiResponse.data!.kartyId,
        kartyUrl: cacheUrl,
        correctText: apiResponse.data!.correctText,
        article: apiResponse.data!.article,
        audioUrl: apiResponse.data!.audioUrl,
        mode: apiResponse.data!.mode,
        stage: apiResponse.data!.stage,
        options: options,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Karty?> _consumePrefetchedCard({required bool reviewMode}) async {
    if (_prefetchFuture == null || _prefetchReviewMode != reviewMode) {
      return null;
    }

    final future = _prefetchFuture;
    _prefetchFuture = null;
    _prefetchReviewMode = null;

    return await future;
  }

  bool _completeLoad() {
    _isLoaded = true;
    notifyListeners();
    return true;
  }

  void removeTopCard() {
    if (_cards.isNotEmpty) {
      _cards.removeAt(0);
      _isLoaded = _cards.isNotEmpty;
      notifyListeners();
    }
  }

  void addNewCard(Karty card) {
    _cards.add(card);
    _isLoaded = true;
    notifyListeners();
  }

  void reset() {
    _generation += 1;
    _preparedLoad = null;
    _fillFuture = null;
    _cards.clear();
    _isLoaded = false;
    _prefetchFuture = null;
    _prefetchReviewMode = null;
    notifyListeners();
  }
}
