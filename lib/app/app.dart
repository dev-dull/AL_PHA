import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/router.dart';
import 'package:alpha/app/theme.dart';
import 'package:alpha/features/auth/providers/auth_providers.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';

class AlphaApp extends ConsumerStatefulWidget {
  const AlphaApp({super.key});

  @override
  ConsumerState<AlphaApp> createState() => _AlphaAppState();
}

class _AlphaAppState extends ConsumerState<AlphaApp> {
  static const _channel = MethodChannel('app.channel/deeplink');
  StreamSubscription<dynamic>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    // Handle deep links via the platform's initial link and stream.
    // On macOS/iOS, the OS delivers the URL when the user clicks
    // an alpha:// link. We intercept it and handle the OAuth code.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        _handleDeepLink(call.arguments as String);
      }
    });

    // Also try getInitialLink for cold-start deep links.
    _channel.invokeMethod<String>('getInitialLink').then((link) {
      if (link != null) _handleDeepLink(link);
    }).catchError((_) {
      // Channel not available on this platform — fall back to
      // GoRouter's built-in deep link handling.
    });
  }

  void _handleDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Cognito redirects to alpha://auth/callback?code=XXX
    // The URI may parse as host=auth, path=/callback
    // or host empty, path=/auth/callback depending on platform.
    final path = uri.host.isEmpty
        ? uri.path
        : '/${uri.host}${uri.path}';

    if (uri.scheme == 'alpha' && path == '/auth/callback') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        _handleAuthCode(code);
      }
    }
  }

  Future<void> _handleAuthCode(String code) async {
    try {
      await ref.read(authProvider.notifier).handleCallback(code);
      router.go('/preferences');
    } catch (e) {
      debugPrint('Auth callback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
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
