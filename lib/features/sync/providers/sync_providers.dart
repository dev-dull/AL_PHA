import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/auth/providers/auth_providers.dart';
import 'package:alpha/features/sync/data/sync_api_client.dart';
import 'package:alpha/features/sync/domain/sync_status.dart';
import 'package:alpha/shared/providers.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
class Sync extends _$Sync {
  final _api = SyncApiClient();
  Timer? _debounce;

  @override
  ({SyncState status, String? lastError, DateTime? lastSyncTime}) build() {
    ref.onDispose(() => _debounce?.cancel());
    return (status: SyncState.idle, lastError: null, lastSyncTime: null);
  }

  /// Run a full sync cycle: push local changes, pull remote.
  Future<void> syncNow() async {
    final auth = ref.read(authProvider);
    if (auth.user == null || auth.tokens == null) {
      debugPrint('[SYNC] Not signed in, skipping');
      return;
    }

    final accessToken =
        await ref.read(authProvider.notifier).getAccessToken();
    if (accessToken == null) {
      debugPrint('[SYNC] No access token (expired/refresh failed)');
      state = (
        status: SyncState.error,
        lastError: 'Session expired — sign in again',
        lastSyncTime: state.lastSyncTime,
      );
      return;
    }
    debugPrint('[SYNC] Starting sync...');

    state = (
      status: SyncState.syncing,
      lastError: null,
      lastSyncTime: state.lastSyncTime,
    );

    try {
      final meta = ref.read(syncMetaRepositoryProvider);
      final tracker = ref.read(changeTrackerProvider);

      // Ensure we have a device ID.
      var deviceId = await meta.getDeviceId();
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await meta.setDeviceId(deviceId);
      }

      final lastSync = await meta.getLastSyncTime();

      // ── Push ──
      final changes = await tracker.getChangesSince(lastSync);
      if (changes.isNotEmpty) {
        final pushResult = await _api.push(
          accessToken: accessToken,
          deviceId: deviceId,
          changes: changes,
        );
        debugPrint('[SYNC] Push: ${pushResult.accepted} accepted, '
            '${pushResult.rejected} rejected');
      }

      // ── Pull ──
      final pullResult = await _api.pull(
        accessToken: accessToken,
        deviceId: deviceId,
        since: lastSync?.toUtc().toIso8601String(),
      );
      if (pullResult.changes.isNotEmpty) {
        await _applyRemoteChanges(pullResult.changes);
        debugPrint('[SYNC] Pull: ${pullResult.changes.length} changes');
      }

      // Update sync cursor.
      final serverTime = DateTime.tryParse(pullResult.serverTime) ??
          DateTime.now().toUtc();
      await meta.setLastSyncTime(serverTime);

      state = (
        status: SyncState.synced,
        lastError: null,
        lastSyncTime: serverTime,
      );
    } catch (e) {
      debugPrint('[SYNC] Error: $e');
      state = (
        status: SyncState.error,
        lastError: e.toString(),
        lastSyncTime: state.lastSyncTime,
      );
    }
  }

  /// Schedule a sync after a short debounce (call after local writes).
  void scheduleSyncAfterWrite() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () {
      syncNow();
    });
  }

  /// Apply remote changes to the local database.
  Future<void> _applyRemoteChanges(
    List<Map<String, dynamic>> changes,
  ) async {
    final db = ref.read(alphaDatabaseProvider);

    for (final change in changes) {
      final table = change['table'] as String?;
      final data = change['data'] as Map<String, dynamic>?;
      final deleted = change['deleted'] as bool? ?? false;

      if (table == null || data == null) continue;

      if (deleted) {
        await _deleteLocal(db, table, data);
      } else {
        await _upsertLocal(db, table, data);
      }
    }
  }

  // Columns that exist in Postgres but not in local SQLite.
  static const _serverOnlyColumns = {
    'deleted_at', 'user_id',
  };

  Future<void> _upsertLocal(
    dynamic db,
    String table,
    Map<String, dynamic> data,
  ) async {
    // Strip columns that exist on the server but not locally.
    final filtered = Map.of(data)
      ..removeWhere((k, _) => _serverOnlyColumns.contains(k));

    // Build column list and values from the data map.
    final columns = filtered.keys.toList();
    final values = filtered.values.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final colStr = columns.join(', ');

    // SQLite UPSERT: INSERT OR REPLACE.
    final sql = 'INSERT OR REPLACE INTO $table ($colStr) '
        'VALUES ($placeholders)';

    await (db as dynamic).customStatement(sql, values);
  }

  Future<void> _deleteLocal(
    dynamic db,
    String table,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'];
    if (id != null) {
      await (db as dynamic).customStatement(
        'DELETE FROM $table WHERE id = ?',
        [id],
      );
    } else if (table == 'task_tags') {
      await (db as dynamic).customStatement(
        'DELETE FROM task_tags WHERE task_id = ? AND tag_id = ?',
        [data['task_id'], data['tag_id']],
      );
    } else if (table == 'series_tags') {
      await (db as dynamic).customStatement(
        'DELETE FROM series_tags WHERE series_id = ? AND tag_id = ?',
        [data['series_id'], data['tag_id']],
      );
    }
  }
}
