import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/auth/domain/auth_state.dart';

/// Regression for #57.
///
/// Pre-fix, AuthTokens.expiresAt round-tripped through JSON as a
/// TZ-naive ISO string. The wall-clock survived but the absolute
/// instant shifted by the host's local-offset difference whenever
/// the user changed timezones — `isExpired` would false-positive,
/// the app would attempt an unnecessary refresh, and any failure
/// in that refresh signed the user out. The fix persists
/// expiresAt as UTC epoch milliseconds (int) so the absolute
/// instant survives serialization regardless of host TZ.
void main() {
  group('AuthTokens.expiresAt persistence', () {
    test('toJson emits UTC epoch milliseconds (int), not a string',
        () {
      final tokens = AuthTokens(
        accessToken: 'a',
        idToken: 'i',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2026, 5, 3, 17, 30),
      );

      final json = tokens.toJson();

      // Critical: int, not string. A string would re-introduce the
      // TZ-naive parse-as-local-on-load bug.
      expect(json['expiresAt'], isA<int>());
      expect(
        json['expiresAt'],
        DateTime.utc(2026, 5, 3, 17, 30).millisecondsSinceEpoch,
      );
    });

    test('round-trip preserves the absolute instant exactly', () {
      final original = AuthTokens(
        accessToken: 'a',
        idToken: 'i',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2026, 5, 3, 17, 30),
      );

      final encoded = jsonEncode(original.toJson());
      final restored = AuthTokens.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored.expiresAt.toUtc(), original.expiresAt.toUtc());
      expect(restored.expiresAt.isUtc, isTrue,
          reason: 'Restored DateTime must be UTC so isExpired '
              'comparisons are TZ-independent');
    });

    test('legacy ISO-string format still parses (back-compat)', () {
      // Existing devices have tokens persisted under the old buggy
      // format — a TZ-naive ISO string with no offset suffix. We
      // accept it and convert to UTC; the next save replaces it
      // with the int format.
      final legacyJson = {
        'accessToken': 'a',
        'idToken': 'i',
        'refreshToken': 'r',
        'expiresAt': '2026-05-03T17:30:00.000',
      };

      final restored = AuthTokens.fromJson(legacyJson);

      expect(restored.expiresAt.isUtc, isTrue);
      // Don't assert the exact instant — depends on the test
      // runner's local TZ — but confirm we got SOMETHING parseable
      // rather than an exception.
      expect(restored.expiresAt.year, 2026);
      expect(restored.expiresAt.month, anyOf(4, 5));
    });

    test('isExpired uses UTC comparison, not host-local', () {
      // expiresAt 1 hour in the future (UTC instant). isExpired
      // must be false regardless of host TZ.
      final futureUtc =
          DateTime.now().toUtc().add(const Duration(hours: 1));
      final tokens = AuthTokens(
        accessToken: 'a',
        idToken: 'i',
        refreshToken: 'r',
        expiresAt: futureUtc,
      );
      expect(tokens.isExpired, isFalse);

      // 1 hour in the past → expired.
      final pastTokens = AuthTokens(
        accessToken: 'a',
        idToken: 'i',
        refreshToken: 'r',
        expiresAt:
            DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      expect(pastTokens.isExpired, isTrue);
    });
  });
}
