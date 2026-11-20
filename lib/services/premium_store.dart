import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:intl/intl.dart';
import 'package:stelinda/ui/screens/premium_screen.dart'
    show PremiumOffer, PremiumPlan;

enum PremiumPurchaseResult { success, failed, canceled, pending }

/// App Store aboneliği (StoreKit 2): ürünler, satın alma, geri yükleme.
///
/// Satın alınan ya da geri yüklenen her işlem sunucuya gider
/// (`POST premium/apple`); sunucu Apple'ın imzasını doğrulayıp premium
/// süresini yazar. İşlem ancak sunucu kabul edince bitirilir: ağ yoksa
/// StoreKit işlemi sonraki açılışta yeniden verir. Uygulama açılır açılmaz
/// dinlemeye başlar ki yarım kalan satın almalar da işlensin.
class PremiumStore {
  PremiumStore({
    required this.verify,
    InAppPurchase? iap,
    Future<bool> Function(String productId)? introEligible,
  })  : _iapOverride = iap,
        _introEligible =
            introEligible ?? SK2Product.isIntroductoryOfferEligible;

  static const yearlyId = 'com.stelinda.app.premium.yearly';
  static const monthlyId = 'com.stelinda.app.premium.monthly';

  /// App Store Connect'teki tanıtım teklifi: 7 gün ücretsiz. StoreKit
  /// sürenin kendisini bu eklenti sürümünde vermiyor, yalnız uygunluğu.
  static const trialDays = 7;

  /// Satın alma şimdilik yalnız iOS'ta (Google Play faturalandırması
  /// kurulana kadar Android'de premium girişleri gizli).
  static bool get supported =>
      debugSupportedOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  /// Testler Android gibi çalışır; önizlemeler iOS'taki görünüşü (premium
  /// girişleri açık) çizsin diye `test/flutter_test_config.dart` bunu açar.
  @visibleForTesting
  static bool? debugSupportedOverride;

  final Future<bool> Function(String signedTransaction) verify;
  final InAppPurchase? _iapOverride;
  final Future<bool> Function(String productId) _introEligible;

  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  final Map<String, ProductDetails> _products = {};
  final _results = StreamController<PremiumPurchaseResult>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Stream<PremiumPurchaseResult> get results => _results.stream;

  void start() {
    if (!supported || _subscription != null) return;
    _subscription = _iap.purchaseStream.listen(
      handlePurchases,
      onError: (_) => _results.add(PremiumPurchaseResult.failed),
    );
  }

  /// Mağazadaki iki planın gerçek fiyatları; mağazaya ulaşılamazsa null.
  Future<PremiumOffer?> loadOffer() async {
    if (!supported) return null;
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({yearlyId, monthlyId});
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }
      final yearly = _products[yearlyId];
      final monthly = _products[monthlyId];
      if (yearly == null || monthly == null) return null;

      var trial = false;
      try {
        trial = await _introEligible(yearlyId);
      } catch (_) {}
      return offerFrom(yearly: yearly, monthly: monthly, trialEligible: trial);
    } catch (error) {
      if (kDebugMode) debugPrint('Premium ürünleri alınamadı: $error');
      return null;
    }
  }

  /// Ekran fiyat hesaplamaz; yıllığın aylık karşılığı ve indirim burada.
  @visibleForTesting
  static PremiumOffer offerFrom({
    required ProductDetails yearly,
    required ProductDetails monthly,
    required bool trialEligible,
  }) {
    final perMonth = NumberFormat.currency(
      locale: 'tr_TR',
      name: yearly.currencyCode,
      symbol: yearly.currencySymbol,
      decimalDigits: 2,
    ).format(yearly.rawPrice / 12);
    final saving = monthly.rawPrice > 0
        ? (100 * (1 - yearly.rawPrice / (monthly.rawPrice * 12))).round()
        : 0;
    return PremiumOffer(
      yearlyPrice: yearly.price,
      yearlyPerMonth: perMonth,
      monthlyPrice: monthly.price,
      yearlySavingPercent: saving.clamp(0, 99),
      trialDays: trialEligible ? trialDays : 0,
    );
  }

  Future<bool> buy(PremiumPlan plan) async {
    final product = _products[plan == PremiumPlan.yearly ? yearlyId : monthlyId];
    if (product == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() => _iap.restorePurchases();

  @visibleForTesting
  Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _results.add(PremiumPurchaseResult.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          var accepted = false;
          try {
            accepted =
                await verify(purchase.verificationData.serverVerificationData);
          } catch (_) {}
          if (accepted && purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _results.add(accepted
              ? PremiumPurchaseResult.success
              : PremiumPurchaseResult.failed);
        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _results.add(PremiumPurchaseResult.canceled);
        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _results.add(PremiumPurchaseResult.failed);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _results.close();
  }
}
