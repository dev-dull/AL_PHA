import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/app/app.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/shared/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AlphaDatabase();

  runApp(
    ProviderScope(
      overrides: [
        alphaDatabaseProvider.overrideWithValue(database),
      ],
      child: const AlphaApp(),
    ),
  );
}
