import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/app.dart';
import 'package:alpha/features/auth/providers/auth_providers.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/shared/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AlphaDatabase();

  final container = ProviderContainer(
    overrides: [alphaDatabaseProvider.overrideWithValue(database)],
  );

  // Load saved preferences and auth state before the first frame.
  await container.read(preferencesProvider.notifier).init();
  await container.read(authProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AlphaApp(),
    ),
  );
}
