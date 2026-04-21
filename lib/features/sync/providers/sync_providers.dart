import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/auth/providers/auth_providers.dart';
import 'package:planyr/features/sync/data/sync_api_client.dart';
import 'package:planyr/features/sync/domain/sync_status.dart';
import 'package:planyr/shared/providers.dart';

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
    if (auth.user == null || auth.tokens == null) return;

    final accessToken =
        await ref.read(authProvider.notifier).getAccessToken();
    if (accessToken == null) {
      state = (
        status: SyncState.error,
        lastError: 'Session expired — sign in again',
        lastSyncTime: state.lastSyncTime,
      );
      return;
    }
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
        await _api.push(
          accessToken: accessToken,
          deviceId: deviceId,
          changes: changes,
        );
      }

      // ── Pull ──
      final pullResult = await _api.pull(
        accessToken: accessToken,
        deviceId: deviceId,
        since: lastSync?.toUtc().toIso8601String(),
      );
      if (pullResult.changes.isNotEmpty) {
        await _applyRemoteChanges(pullResult.changes);
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
    final db = ref.read(planyrDatabaseProvider);

    for (final change in changes) {
      final table = change['table'] as String?;
      final data = change['data'] as Map<String, dynamic>?;
      final deleted = change['deleted'] as bool? ?? false;

      if (table == null || data == null) continue;

      if (deleted) {
        await _deleteLocal(db, table, data);
      } else {
        // Skip boards that would create a week_start duplicate.
        if (table == 'boards' && data['week_start'] != null) {
          final ws = _toEpochSeconds('week_start', data['week_start']);
          final existing = await db.customSelect(
            'SELECT id FROM boards WHERE week_start = ?',
            variables: [Variable(ws)],
          ).get();
          if (existing.isNotEmpty) continue;
        }
        await _upsertLocal(db, table, data);
      }
    }
  }

  // Columns that exist in Postgres but not in local SQLite.
  static const _serverOnlyColumns = {
    'deleted_at', 'user_id',
  };

  // Columns that are timestamps — Postgres returns ISO strings,
  // but Drift/SQLite expects epoch seconds (integers).
  static const _timestampColumns = {
    'created_at', 'updated_at', 'completed_at', 'deadline',
    'week_start', 'ended_at',
  };

  /// Convert a Postgres ISO timestamp string to epoch seconds
  /// for SQLite storage. Returns the value unchanged if it's
  /// already an int or null.
  static dynamic _toEpochSeconds(String key, dynamic value) {
    if (!_timestampColumns.contains(key)) return value;
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return value;
  }

  Future<void> _upsertLocal(
    dynamic db,
    String table,
    Map<String, dynamic> data,
  ) async {
    // Strip server-only columns and convert timestamps.
    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      if (_serverOnlyColumns.contains(entry.key)) continue;
      filtered[entry.key] = _toEpochSeconds(entry.key, entry.value);
    }

    // Build column list and values from the data map.
    final columns = filtered.keys.toList();
    final values = filtered.values.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final colStr = columns.join(', ');

    // Use INSERT OR IGNORE — don't overwrite existing local data.
    // Local is source of truth; pull only adds rows we don't have.
    final sql = 'INSERT OR IGNORE INTO $table ($colStr) '
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
