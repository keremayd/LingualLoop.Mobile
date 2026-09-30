import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/responses/ResolveWrongKartyReviewResponse.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';

void main() {
  test('rovanş cevabi verilen bilet sayisini okur', () {
    final response = ResolveWrongKartyReviewResponse.fromJson({
      'userId': 'user-1',
      'kartyId': 12,
      'isMastered': true,
      'wrongCount': 2,
      'reviewedDate': '2026-08-21T10:00:00Z',
      'rewardTickets': 1,
    });

    expect(response.rewardTickets, 1);
    expect(response.reviewedDate?.isUtc, isTrue);
  });

  testWidgets('tamamlanma ekrani bilet odulunu gosterir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: KartyReviewCompleteState(
            scale: 430 / 750,
            rewardTickets: 1,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('+1 bilet kazandın'), findsOneWidget);
  });
}
