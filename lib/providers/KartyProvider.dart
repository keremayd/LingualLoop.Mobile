import 'package:flutter/material.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';

class KartyProvider with ChangeNotifier {
  final List<Karty> _cards = [];
  bool _isLoaded = false;
  Future<Karty?>? _prefetchFuture;
  bool? _prefetchReviewMode;

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

      for (var i = 0; i < 3; i++) {
        final card = await _fetchUniqueKarty(
          kartyService,
          localFileService,
          reviewMode: reviewMode,
        );
        if (card == null) {
          _isLoaded = _cards.isNotEmpty;
          notifyListeners();
          return _cards.isNotEmpty;
        }

        _cards.add(card);
      }

      return _completeLoad();
    }

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

  void prefetchNextKarty(BuildContext context, {required bool reviewMode}) {
    if (_prefetchFuture != null && _prefetchReviewMode == reviewMode) {
      return;
    }

    final kartyService = Provider.of<KartyService>(context, listen: false);
    final localFileService =
        Provider.of<LocalFileService>(context, listen: false);
    final queuedCards = _cards.skip(1).toList();

    _prefetchReviewMode = reviewMode;
    _prefetchFuture = _fetchUniqueKarty(
      kartyService,
      localFileService,
      reviewMode: reviewMode,
      queuedCards: queuedCards,
    );
  }

  Future<Karty?> _fetchUniqueKarty(
    KartyService kartyService,
    LocalFileService localFileService, {
    required bool reviewMode,
    List<Karty>? queuedCards,
  }) async {
    final cardsToCheck = queuedCards ?? _cards;

    for (var attempt = 0; attempt < 5; attempt++) {
      final card = await _fetchKarty(
        kartyService,
        localFileService,
        reviewMode: reviewMode,
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
      {required bool reviewMode}) async {
    try {
      final apiResponse = reviewMode
          ? await kartyService.randomWrong()
          : await kartyService.random();
      if (apiResponse.errorCode != null || apiResponse.data == null) {
        return null;
      }

      // Gelen signedUrl'deki karty görselini cache'e aktarıyoruz
      final cacheUrl = await localFileService.cacheKartyImage(
        apiResponse.data!.kartyUrl,
        apiResponse.data!.kartyId,
      );

      // Cache'teki kaydettiğimiz adres üzerinden ilerletiyoruz
      return Karty(
        kartyId: apiResponse.data!.kartyId,
        kartyUrl: cacheUrl,
        questionText: apiResponse.data!.questionText,
        correctText: apiResponse.data!.correctText,
        isCorrect: apiResponse.data!.isCorrect,
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
    _cards.clear();
    _isLoaded = false;
    _prefetchFuture = null;
    _prefetchReviewMode = null;
    notifyListeners();
  }
}
