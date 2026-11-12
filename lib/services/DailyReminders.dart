import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/timezone.dart' as tz;

class DailyReminder {
  const DailyReminder({
    required this.at,
    required this.title,
    required this.body,
  });

  final DateTime at;
  final String title;
  final String body;
}

const _reminderHour = 20;

/// Oyuncu dönmezse kaç gün üst üste hatırlatılacağı. Sonrasında susulur:
/// karşılık bulmayan bildirim kanalı kapattırır.
const _reminderDays = 3;

/// Önümüzdeki hatırlatmalar: günde en çok bir tane, o gün oynandıysa ertesi
/// günden başlar.
List<DailyReminder> planDailyReminders({
  required DateTime now,
  required bool playedToday,
  required int streak,
}) {
  final remindToday =
      !playedToday && now.isBefore(DateTime(now.year, now.month, now.day, _reminderHour));
  final firstDay = remindToday ? 0 : 1;
  // Seri ilk hatırlatmaya kadar ancak bugün oynandıysa ya da hatırlatma bugünse
  // ayakta kalır; sonrakiler kaçırılmış günlerin ardından gelir.
  final streakAlive = streak > 0 && (remindToday || playedToday);

  return [
    for (var day = 0; day < _reminderDays; day++)
      _reminder(
        DateTime(now.year, now.month, now.day + firstDay + day, _reminderHour),
        day: day,
        streak: streak,
        streakAlive: streakAlive,
      ),
  ];
}

DailyReminder _reminder(
  DateTime at, {
  required int day,
  required int streak,
  required bool streakAlive,
}) {
  if (day == 0 && streakAlive) {
    return DailyReminder(
      at: at,
      title: '$streak günlük serin bekliyor',
      body: 'Bugün bir oyun oyna, serin devam etsin.',
    );
  }
  if (day == 1 || (day == 0 && streak > 0)) {
    return DailyReminder(
      at: at,
      title: 'Seni özledik',
      body: 'Birkaç kelimeyle kaldığın yerden devam et.',
    );
  }
  return DailyReminder(
    at: at,
    title: 'Bugünün kelimeleri hazır',
    body: 'Günde birkaç dakika yeter.',
  );
}

/// Sunucusuz günlük hatırlatma. Plan her oyun durumu değiştiğinde baştan
/// kurulur, böylece oynanan günün bildirimi çalmaz. Bildirim hatası oyunu
/// asla etkilemez.
abstract final class DailyReminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();
  static const _askedKey = 'dailyReminderPermissionAsked';
  static const _firstId = 7100;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Günlük hatırlatma',
      channelDescription: 'Bugün oynamadıysan günde en çok bir kez hatırlatır.',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static ({DateTime day, bool playedToday, int streak})? _planned;

  static Future<void> init() async {
    try {
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // İzin açılışta değil, ilk oyundan sonra sorulur.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));
    } catch (_) {}
  }

  /// İzni bir kez, ilk oyunu bitiren kullanıcıya sorar: uygulamayı açar açmaz
  /// sorulan izin çoğunlukla reddedilir.
  static Future<void> askPermissionOnce() async {
    try {
      if (await _storage.read(key: _askedKey) != null) return;
      await _storage.write(key: _askedKey, value: 'true');

      if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true);
      } else {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      final planned = _planned;
      if (planned == null) return;
      _planned = null;
      await sync(playedToday: planned.playedToday, streak: planned.streak);
    } catch (_) {}
  }

  /// Oyun durumu her tazelendiğinde çağrılır; durum değişmediyse dokunmaz.
  static Future<void> sync({
    required bool playedToday,
    required int streak,
  }) async {
    final now = DateTime.now();
    final state = (
      day: DateTime(now.year, now.month, now.day),
      playedToday: playedToday,
      streak: streak,
    );
    if (state == _planned) return;
    _planned = state;

    try {
      await _plugin.cancelAll();
      final plan = planDailyReminders(
        now: now,
        playedToday: playedToday,
        streak: streak,
      );
      for (final (index, reminder) in plan.indexed) {
        await _plugin.zonedSchedule(
          _firstId + index,
          reminder.title,
          reminder.body,
          tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // Bir sonraki tazelemede yeniden denensin.
      _planned = null;
    }
  }

  /// Oturum kapanınca eski hesabın hatırlatmaları çalmasın.
  static Future<void> cancel() async {
    _planned = null;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
