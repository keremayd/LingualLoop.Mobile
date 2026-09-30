import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:provider/provider.dart';

class ProfileLearningStatsProvider with ChangeNotifier {
  ProfileLearningStatsResponse? _stats;
  Future<ProfileLearningStatsResponse?>? _prefetchedStatsFuture;
  bool _isLoading = false;
  bool _hasError = false;

  ProfileLearningStatsResponse? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<bool> load(BuildContext context) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    final isLoaded = await refreshSilently(context);
    if (isLoaded) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _hasError = true;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> refreshSilently(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    return refreshFromService(userService);
  }

  Future<bool> refreshFromService(UserService userService) async {
    final stats = await fetchWithoutNotifying(userService);
    if (stats == null) return false;

    applyFetchedStats(stats);
    return true;
  }

  /// Veriyi hazırlar fakat dinleyicilere uygulamaz. Oyun ekranı Home'un
  /// arkasındayken kartların görünmez biçimde durum değiştirmesini önler.
  Future<ProfileLearningStatsResponse?> fetchWithoutNotifying(
    UserService userService,
  ) async {
    try {
      final response = await userService.profileLearningStatsById();
      if (response.errorCode == null && response.data != null) {
        return response.data;
      }
    } catch (_) {
      // Profile stats are supportive data; stale values are safer than blocking.
    }
    return null;
  }

  /// Karty içindeyken en güncel profil bilgisini Home dönüşü için hazırlar.
  void prefetchForHome(UserService userService) {
    _prefetchedStatsFuture = fetchWithoutNotifying(userService);
  }

  /// Hazır bir istek varsa onu tüketir; yoksa yeni isteği hemen başlatır.
  Future<ProfileLearningStatsResponse?> consumePrefetchOrFetch(
    UserService userService,
  ) {
    final future = _prefetchedStatsFuture ?? fetchWithoutNotifying(userService);
    _prefetchedStatsFuture = null;
    return future;
  }

  void applyFetchedStats(ProfileLearningStatsResponse stats) {
    _stats = stats;
    _hasError = false;
    notifyListeners();
  }

  /// Yalnızca golden önizlemesi için: ağ isteği olmadan veri yerleştirir.
  @visibleForTesting
  void applyPreviewStats(ProfileLearningStatsResponse stats) {
    _stats = stats;
  }

  void applyDailyActivity(DailyActivityResponse activity) {
    final currentStats = _stats;
    if (currentStats == null) return;

    _stats = currentStats.copyWith(
      currentStreak: activity.currentStreak,
      longestStreak: activity.longestStreak,
      freezeCount: activity.freezeCount,
      week: activity.week,
    );
    notifyListeners();
  }
}
