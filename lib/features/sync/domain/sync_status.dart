enum SyncState {
  /// Not signed in — sync disabled.
  idle,

  /// Sync in progress.
  syncing,

  /// Last sync succeeded.
  synced,

  /// Last sync failed.
  error,
}
