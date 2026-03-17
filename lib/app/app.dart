import 'package:flutter/material.dart';
import 'package:alpha/app/router.dart';
import 'package:alpha/app/theme.dart';

class AlphaApp extends StatelessWidget {
  const AlphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AlPHA',
      debugShowCheckedModeBanner: false,
      theme: AlphaTheme.light(),
      darkTheme: AlphaTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
