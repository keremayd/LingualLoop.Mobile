import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/services/AuthenticationService.dart';
import 'package:stelinda/services/account_deletion.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Silme isteklerini sırayla cevaplar ve gönderilenleri saklar.
class _Server {
  _Server(this.answers);

  final List<AccountDeletionResult> answers;
  final calls = <({String? code, bool skip})>[];

  Future<AccountDeletionResult> delete({
    String? appleAuthorizationCode,
    bool skipAppleRevocation = false,
  }) async {
    calls.add((code: appleAuthorizationCode, skip: skipAppleRevocation));
    return answers[calls.length - 1];
  }
}

void main() {
  group('Hesap silme ve Apple onayı', () {
    test('Apple ile bağlı değilse tek istekle silinir, Apple sorulmaz',
        () async {
      final server = _Server([AccountDeletionResult.deleted]);
      var asked = false;
      final result = await deleteAccountWithAppleConsent(
        delete: server.delete,
        appleAuthorizationCode: () async {
          asked = true;
          return 'kod';
        },
        appleAvailable: true,
      );
      expect(result, AccountDeletionResult.deleted);
      expect(server.calls, [(code: null, skip: false)]);
      expect(asked, isFalse);
    });

    test('Apple onayı istenince Apple penceresinin koduyla yeniden gider',
        () async {
      final server = _Server([
        AccountDeletionResult.appleConsentRequired,
        AccountDeletionResult.deleted,
      ]);
      final result = await deleteAccountWithAppleConsent(
        delete: server.delete,
        appleAuthorizationCode: () async => 'kod',
        appleAvailable: true,
      );
      expect(result, AccountDeletionResult.deleted);
      expect(server.calls, [
        (code: null, skip: false),
        (code: 'kod', skip: false),
      ]);
    });

    test('Apple penceresi kapatılırsa hesap silinmez', () async {
      final server = _Server([AccountDeletionResult.appleConsentRequired]);
      final result = await deleteAccountWithAppleConsent(
        delete: server.delete,
        appleAuthorizationCode: () async => null,
        appleAvailable: true,
      );
      expect(result, AccountDeletionResult.appleConsentCanceled);
      expect(server.calls, hasLength(1));
    });

    test('Apple penceresi olmayan platformda izin geri alınmadan silinir',
        () async {
      final server = _Server([
        AccountDeletionResult.appleConsentRequired,
        AccountDeletionResult.deleted,
      ]);
      final result = await deleteAccountWithAppleConsent(
        delete: server.delete,
        appleAuthorizationCode: () async => fail('Apple penceresi açılmamalı'),
        appleAvailable: false,
      );
      expect(result, AccountDeletionResult.deleted);
      expect(server.calls.last, (code: null, skip: true));
    });

    test('Sunucu kodla da onay isterse silinmedi sayılır', () async {
      final server = _Server([
        AccountDeletionResult.appleConsentRequired,
        AccountDeletionResult.appleConsentRequired,
      ]);
      final result = await deleteAccountWithAppleConsent(
        delete: server.delete,
        appleAuthorizationCode: () async => 'kod',
        appleAvailable: true,
      );
      expect(result, AccountDeletionResult.failed);
    });
  });

  group('Apple onay kodu', () {
    test('Apple penceresinin yetki kodu döner', () async {
      final auth = AuthService(Dio(),
          appleCredential: (_) async => const AuthorizationCredentialAppleID(
                userIdentifier: '001234.abcd',
                givenName: null,
                familyName: null,
                authorizationCode: 'tek-kullanimlik-kod',
                email: null,
                identityToken: 'apple-kimlik-token',
                state: null,
              ));
      expect(await auth.requestAppleAuthorizationCode(), 'tek-kullanimlik-kod');
    });

    test('Pencere kapatılırsa ya da Apple hata verirse null', () async {
      for (final code in [
        AuthorizationErrorCode.canceled,
        AuthorizationErrorCode.failed,
      ]) {
        final auth = AuthService(Dio(),
            appleCredential: (_) async =>
                throw SignInWithAppleAuthorizationException(
                  code: code,
                  message: 'apple',
                ));
        expect(await auth.requestAppleAuthorizationCode(), isNull);
      }
    });
  });
}
