import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:planyr/app/app.dart';
import 'package:planyr/features/auth/domain/auth_state.dart';
import 'package:planyr/features/auth/providers/auth_providers.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/features/sync/providers/sync_providers.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IANA tzdata for converting iCal `TZID=...` wall-clock times
  // into UTC on import. Without this, an event imported from
  // `America/New_York` would land at the host's offset instead of
  // its intended absolute moment.
  tzdata.initializeTimeZones();

  final database = PlanyrDatabase();

  final container = ProviderContainer(
    overrides: [planyrDatabaseProvider.overrideWithValue(database)],
  );

  // Load saved preferences and auth state before the first frame.
  await container.read(preferencesProvider.notifier).init();
  await container.read(authProvider.notifier).init();

  // Trigger a sync on every signed-out → signed-in transition.
  // Registered on the container (not via ref.listen inside the Sync
  // notifier) so it fires regardless of whether anything has yet
  // read syncProvider — otherwise an early sign-in could happen
  // before Sync.build runs and the listener would never register.
  // Placed after auth.init() so the listener doesn't fire on the
  // initial state hydration; the bootstrap sync below handles that.
  container.listen<({AuthUser? user, AuthTokens? tokens})>(
    authProvider,
    (prev, next) {
      final wasSignedOut = prev == null || prev.user == null;
      final isSignedIn = next.user != null;
      if (wasSignedOut && isSignedIn) {
        container.read(syncProvider.notifier).syncNow();
      }
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PlanyrApp(),
    ),
  );

  // Bootstrap sync after the UI has settled if we're already
  // signed in from persisted tokens (the listener above won't
  // fire on init() because it's registered after init completes).
  if (container.read(authProvider).user != null) {
    Future.delayed(const Duration(seconds: 3), () {
      container.read(syncProvider.notifier).syncNow();
    });
  }
}
