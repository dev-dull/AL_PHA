import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planyr/app/router.dart';
import 'package:planyr/app/theme.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';

class PlanyrApp extends ConsumerWidget {
  const PlanyrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'planyr',
      debugShowCheckedModeBanner: false,
      theme: PlanyrTheme.light(fontFamily: prefs.fontFamily),
      darkTheme: PlanyrTheme.dark(fontFamily: prefs.fontFamily),
      themeMode: prefs.themeMode,
      routerConfig: router,
    );
  }
}
