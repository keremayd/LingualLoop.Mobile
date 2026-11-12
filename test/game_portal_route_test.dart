import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/ticket_spend_scene.dart';

/// Oyunu açan daire zamana değil kareye bağlı ilerler. Oyun sayfasının ilk
/// karesi ağır (kurulum ve ekran dışında ölçüm, debug'da 200 ms'ye kadar);
/// zamana bağlıyken daire o karede yarısına kadar sıçrıyordu, kullanıcı "dona
/// dona açılıyor, dona dona kapanıyor" dedi (12 Kas 2026).
void main() {
  Future<(GamePortalRoute<void>, GamePortal)> open(WidgetTester tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox.expand()),
    );
    final portal = GamePortal(center: const Offset(200, 300), startRadius: 30);
    final route = GamePortalRoute<void>(
      settings: const RouteSettings(name: '/oyun'),
      builder: (_) => const ColoredBox(key: Key('oyun'), color: Colors.blue),
      portal: portal,
    );
    navigator.currentState!.push(route);
    await tester.pump();
    return (route, portal);
  }

  Future<void> frames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('ağır kare daireyi sıçratmaz, yalnız bekletir', (tester) async {
    final (route, portal) = await open(tester);

    await tester.pump(const Duration(milliseconds: 300));
    // 300 ms'lik kare 520 ms'lik açılışın en çok iki karelik yolunu açar;
    // zamana bağlıyken %58'ini açıyordu.
    expect(route.animation!.value, lessThan(0.07));

    await frames(tester, 40);
    expect(route.animation!.status, AnimationStatus.completed);
    // Bilet sahnesinin karartması daireyle aynı değeri izler.
    expect(portal.opening.value, 1);
  });

  testWidgets('kapanış da kareyle ilerler', (tester) async {
    final (route, portal) = await open(tester);
    await frames(tester, 40);

    route.navigator!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    // 300 ms'lik kapanışta 250 ms'lik kare de en çok iki kare ilerletir.
    expect(route.animation!.value, greaterThan(0.85));
    expect(portal.opening.value, lessThan(1));

    await frames(tester, 30);
    expect(find.byKey(const Key('oyun')), findsNothing);
  });
}
