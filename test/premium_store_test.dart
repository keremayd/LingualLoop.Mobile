import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:stelinda/services/premium_store.dart';

ProductDetails _product(String id, double price, String label) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: label,
      rawPrice: price,
      currencyCode: 'TRY',
      currencySymbol: '₺',
    );

/// Bitirilen işlemleri sayar; başka bir şey çağrılırsa test düşer.
class _Iap extends Fake implements InAppPurchase {
  final completed = <String>[];

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);
}

PurchaseDetails _purchase(PurchaseStatus status) => PurchaseDetails(
      productID: PremiumStore.yearlyId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'imzali-islem',
        source: 'app_store',
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

void main() {
  test('Teklif mağaza fiyatlarından kurulur', () {
    final offer = PremiumStore.offerFrom(
      yearly: _product(PremiumStore.yearlyId, 900, '₺900,00'),
      monthly: _product(PremiumStore.monthlyId, 150, '₺150,00'),
      trialEligible: true,
    );
    expect(offer.yearlyPrice, '₺900,00');
    expect(offer.monthlyPrice, '₺150,00');
    expect(offer.yearlyPerMonth, '₺75,00');
    expect(offer.yearlySavingPercent, 50);
    expect(offer.trialDays, PremiumStore.trialDays);
  });

  test('Denemeye uygun değilse deneme gösterilmez', () {
    final offer = PremiumStore.offerFrom(
      yearly: _product(PremiumStore.yearlyId, 900, '₺900,00'),
      monthly: _product(PremiumStore.monthlyId, 150, '₺150,00'),
      trialEligible: false,
    );
    expect(offer.trialDays, 0);
  });

  test('Sunucu kabul edince işlem bitirilir ve başarı yayınlanır', () async {
    final iap = _Iap();
    final sent = <String>[];
    final store = PremiumStore(
      iap: iap,
      introEligible: (_) async => true,
      verify: (jws) async {
        sent.add(jws);
        return true;
      },
    );
    final results = <PremiumPurchaseResult>[];
    store.results.listen(results.add);

    await store.handlePurchases([_purchase(PurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(sent, ['imzali-islem']);
    expect(iap.completed, [PremiumStore.yearlyId]);
    expect(results, [PremiumPurchaseResult.success]);
  });

  test('Sunucu reddederse işlem bitirilmez, StoreKit sonra yeniden verir',
      () async {
    final iap = _Iap();
    final store = PremiumStore(
      iap: iap,
      introEligible: (_) async => true,
      verify: (_) async => false,
    );
    final results = <PremiumPurchaseResult>[];
    store.results.listen(results.add);

    await store.handlePurchases([_purchase(PurchaseStatus.restored)]);
    await pumpEventQueue();

    expect(iap.completed, isEmpty);
    expect(results, [PremiumPurchaseResult.failed]);
  });

  test('Vazgeçilen satın alma bitirilir', () async {
    final iap = _Iap();
    final store = PremiumStore(
      iap: iap,
      introEligible: (_) async => true,
      verify: (_) async => fail('sunucuya gitmemeli'),
    );
    final results = <PremiumPurchaseResult>[];
    store.results.listen(results.add);

    await store.handlePurchases([_purchase(PurchaseStatus.canceled)]);
    await pumpEventQueue();

    expect(iap.completed, [PremiumStore.yearlyId]);
    expect(results, [PremiumPurchaseResult.canceled]);
  });
}
