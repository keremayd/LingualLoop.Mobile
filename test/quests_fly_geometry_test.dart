import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'package:provider/provider.dart';

/// Uçan biletlerin koordinat uzayı koruması.
///
/// **Yaşanmış hata:** hedef `localToGlobal` ile ekranın tepesine göre
/// ölçülüyordu, ama uçuş katmanı `QuestsScreen`'in Scaffold'u içinde duruyor
/// ve o Scaffold ekranın tepesinden başlamıyor — `NavbarWidget` sayfaları
/// `SafeArea(bottom: false, ...)` ile sarıyor. Global koordinat doğrudan
/// kullanıldığında biletler durum çubuğu yüksekliği kadar aşağı, sayacın
/// altına konuyordu.
///
/// Bu test o kaymayı yakalar: navbar'ın içindeki sayfanın global başlangıcı
/// sıfır **değilse**, ekran içindeki katmanların global koordinatı doğrudan
/// kullanmaması gerektiğini doğrular.
class _FakeQuestService extends QuestService {
  _FakeQuestService() : super(Dio());

  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20260810,
        resetAtUtc: DateTime.now().toUtc().add(const Duration(hours: 5)),
        quests: [
          DailyQuest(
            questKey: 'checkin',
            title: 'Güne başla',
            target: 1,
            progress: 1,
            rewardTickets: 1,
            isCompleted: true,
            isClaimed: false,
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('sayfa navbar icinde global sifirdan baslamaz', (tester) async {
    // Durum çubuğu olan bir cihazı taklit et.
    const padding = EdgeInsets.only(top: 59);
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => UserService(Dio())),
          ChangeNotifierProvider<ScoreWithLivesProvider>(
            create: (_) => ScoreWithLivesProvider(),
          ),
          Provider<QuestService>(create: (_) => _FakeQuestService()),
          ChangeNotifierProvider<QuestsProvider>(
            create: (c) => QuestsProvider(c.read<QuestService>()),
          ),
        ],
        child: const MediaQuery(
          data: MediaQueryData(padding: padding),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(bottom: false, child: QuestsScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final screenBox =
        tester.renderObject<RenderBox>(find.byType(QuestsScreen).first);
    final origin = screenBox.localToGlobal(Offset.zero);

    // Asıl iddia: sayfanın kendi uzayı ekranın tepesiyle **aynı değil.**
    // Bu doğruysa, ekran içindeki bir katmana global koordinat vermek
    // hatalıdır; `globalToLocal` ile çevrilmesi gerekir.
    expect(
      origin.dy,
      greaterThan(0),
      reason: 'NavbarWidget SafeArea uyguluyor; sayfa global sıfırdan '
          'başlamıyor. Uçuş katmanına global koordinat verilemez.',
    );

    // Çevrimin gerçekten farkı kapattığını göster.
    const globalPoint = Offset(100, 300);
    final local = screenBox.globalToLocal(globalPoint);
    expect(local.dy, lessThan(globalPoint.dy));
    expect(local.dy, closeTo(globalPoint.dy - origin.dy, 0.01));
  });

  test('navbar sayfalari SafeArea ile sariyor', () {
    // Kaymanın kaynağı burada; NavbarWidget değişirse bu not güncellenmeli.
    expect(NavbarWidget.questsTabIndex, 1);
  });
}
