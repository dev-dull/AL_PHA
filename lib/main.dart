import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planyr/app/app.dart';
import 'package:planyr/features/auth/providers/auth_providers.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/features/sync/providers/sync_providers.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = PlanyrDatabase();

  final container = ProviderContainer(
    overrides: [planyrDatabaseProvider.overrideWithValue(database)],
  );

  // Load saved preferences and auth state before the first frame.
  await container.read(preferencesProvider.notifier).init();
  await container.read(authProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PlanyrApp(),
    ),
  );

  // Sync after the UI has settled (boards already loaded).
  if (container.read(authProvider).user != null) {
    Future.delayed(const Duration(seconds: 3), () {
      container.read(syncProvider.notifier).syncNow();
    });
  }
}
