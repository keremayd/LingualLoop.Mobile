import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/services/DailyReminders.dart';

void main() {
  List<DailyReminder> plan(int hour,
          {required bool played, required int streak}) =>
      planDailyReminders(
        now: DateTime(2026, 11, 9, hour),
        playedToday: played,
        streak: streak,
      );

  List<int> daysOf(List<DailyReminder> reminders) =>
      reminders.map((r) => r.at.day).toList();

  test('oynanmadıysa bugün saat 20:00 hatırlatır', () {
    final reminders = plan(10, played: false, streak: 4);

    expect(daysOf(reminders), [9, 10, 11]);
    expect(reminders.first.at.hour, 20);
    expect(reminders.first.title, '4 günlük serin bekliyor');
  });

  test('oynandıysa bugün hatırlatmaz, yarın seri canlıdır', () {
    final reminders = plan(10, played: true, streak: 5);

    expect(daysOf(reminders), [10, 11, 12]);
    expect(reminders.first.title, '5 günlük serin bekliyor');
  });

  test('saat geçtiyse ve oynanmadıysa seri canlı sayılmaz', () {
    final reminders = plan(21, played: false, streak: 4);

    expect(daysOf(reminders), [10, 11, 12]);
    expect(reminders.first.title, 'Seni özledik');
  });

  test('seri yokken davet eder', () {
    final reminders = plan(10, played: false, streak: 0);

    expect(reminders.first.title, 'Bugünün kelimeleri hazır');
  });

  test('her güne en çok bir tane düşer ve üç günde susar', () {
    final reminders = plan(10, played: false, streak: 2);

    expect(reminders, hasLength(3));
    expect(daysOf(reminders).toSet(), hasLength(3));
  });

  test('ay sonunu aşan tarih doğru kurulur', () {
    final reminders = planDailyReminders(
      now: DateTime(2026, 11, 30, 21),
      playedToday: true,
      streak: 1,
    );

    expect(reminders.first.at, DateTime(2026, 12, 1, 20));
  });
}
