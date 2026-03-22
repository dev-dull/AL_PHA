import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/router.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';

class AlphaApp extends ConsumerWidget {
  const AlphaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'AlPHA',
      debugShowCheckedModeBanner: false,
      theme: AlphaTheme.light(fontFamily: prefs.fontFamily),
      darkTheme: AlphaTheme.dark(fontFamily: prefs.fontFamily),
      themeMode: prefs.themeMode,
      routerConfig: router,
    );
  }
}
