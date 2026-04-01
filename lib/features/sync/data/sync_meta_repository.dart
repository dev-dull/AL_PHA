import 'package:alpha/shared/database.dart';

/// Stores sync metadata (device_id, last_sync_time) in a local
/// key-value table that survives app restarts.
class SyncMetaRepository {
  final AlphaDatabase _db;

  SyncMetaRepository(this._db);

  static const keyDeviceId = 'device_id';
  static const keyLastSyncTime = 'last_sync_time';

  Future<String?> get(String key) async {
    final query = _db.select(_db.syncMeta)
      ..where((t) => t.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db.into(_db.syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(key: key, value: value),
    );
  }

  Future<String?> getDeviceId() => get(keyDeviceId);

  Future<void> setDeviceId(String id) => set(keyDeviceId, id);

  Future<DateTime?> getLastSyncTime() async {
    final value = await get(keyLastSyncTime);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastSyncTime(DateTime time) =>
      set(keyLastSyncTime, time.toUtc().toIso8601String());
}
