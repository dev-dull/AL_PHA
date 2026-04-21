import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/app/theme.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

/// Creates a [ProviderContainer] backed by an in-memory Drift database.
///
/// Use this when you need to seed data before pumping a widget.
/// The database and container are cleaned up via [addTearDown].
ProviderContainer createTestContainer() {
  final db = PlanyrDatabase.forTesting(NativeDatabase.memory());

  final container = ProviderContainer(
    overrides: [planyrDatabaseProvider.overrideWithValue(db)],
  );

  addTearDown(() {
    container.dispose();
    db.close();
  });

  return container;
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a [ProviderScope] backed by an in-memory
  /// Drift database, wrapped in a [MaterialApp] with the light theme.
  ///
  /// Returns the [ProviderContainer] so tests can seed data and read
  /// providers.
  Future<ProviderContainer> pumpApp(Widget widget) async {
    final container = createTestContainer();
    await pumpWithContainer(widget, container);
    return container;
  }

  /// Pumps [widget] using an existing [ProviderContainer].
  ///
  /// Use after [createTestContainer] + seeding data so the widget
  /// sees pre-existing data on first build.
  Future<void> pumpWithContainer(
    Widget widget,
    ProviderContainer container,
  ) async {
    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PlanyrTheme.light(),
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
