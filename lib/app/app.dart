import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/router.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';

class AlphaApp extends ConsumerStatefulWidget {
  const AlphaApp({super.key});

  @override
  ConsumerState<AlphaApp> createState() => _AlphaAppState();
}

class _AlphaAppState extends ConsumerState<AlphaApp> {
  static const _channel = MethodChannel('app.channel/deeplink');

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        _handleDeepLink(call.arguments as String);
      }
    });

    _channel.invokeMethod<String>('getInitialLink').then((link) {
      if (link != null) _handleDeepLink(link);
    }).catchError((_) {});
  }

  void _handleDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Cognito redirects to alpha://auth/callback?code=XXX
    final path = uri.host.isEmpty
        ? uri.path
        : '/${uri.host}${uri.path}';

    if (uri.scheme == 'alpha' && path == '/auth/callback') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        // Navigate to the callback screen — it handles the token
        // exchange and shows errors within its own scaffold.
        router.go('/auth/callback?code=$code');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
