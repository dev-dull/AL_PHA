"""Unit tests for sync_push.py — focused on the SAVEPOINT fix and
the natural-key fallback for markers (issue #59).

Run from the lambda/ directory:

    PYTHONPATH=. python3 -m pytest tests/test_sync_push.py -v

Or via unittest discovery:

    PYTHONPATH=. python3 -m unittest discover tests -v
"""

import sys
import unittest
from contextlib import contextmanager
from unittest.mock import MagicMock, patch

# psycopg2.sql is real here — we want SQL composition to actually
# render so the assertions on calls aren't just mock-vs-mock.
from psycopg2 import sql

# Make the lambda package importable when running from this dir.
sys.path.insert(0, "..")

import sync_push  # noqa: E402
from shared import db  # noqa: E402


class SavepointTests(unittest.TestCase):
    """db.savepoint() must isolate row failures from the surrounding
    transaction — RELEASE on success, ROLLBACK TO on exception, and
    NEVER discard the outer transaction."""

    def setUp(self):
        self.executed = []  # captures (rendered_sql, params)
        self._exec_patch = patch.object(db, "execute", self._fake_execute)
        self._exec_patch.start()
        self.addCleanup(self._exec_patch.stop)
        # Reset the module-level flag in case a previous test left
        # it set after an unhandled exception.
        db._in_savepoint = False

    def _fake_execute(self, query, params=None):
        # Capture the Composed SQL itself; tests assert on its
        # `seq` attribute which holds the SQL string fragments.
        # This avoids needing a real psycopg2 connection just to
        # render Identifiers.
        self.executed.append((query, params))
        return []

    def _command_for(self, idx):
        """Pull the leading SQL keyword(s) out of a captured query."""
        query, _ = self.executed[idx]
        if isinstance(query, sql.Composed):
            first = query.seq[0]
            return first.string if isinstance(first, sql.SQL) else str(first)
        return str(query)

    def test_release_on_success(self):
        with db.savepoint("sp_0"):
            pass
        self.assertEqual(len(self.executed), 2)
        self.assertEqual(self._command_for(0), "SAVEPOINT ")
        self.assertEqual(self._command_for(1), "RELEASE SAVEPOINT ")
        self.assertFalse(db._in_savepoint,
                         "_in_savepoint must be cleared after a normal exit")

    def test_rollback_on_exception(self):
        with self.assertRaises(RuntimeError):
            with db.savepoint("sp_1"):
                raise RuntimeError("simulated row failure")
        self.assertEqual(len(self.executed), 2)
        self.assertEqual(self._command_for(0), "SAVEPOINT ")
        self.assertEqual(self._command_for(1), "ROLLBACK TO SAVEPOINT ")
        self.assertFalse(db._in_savepoint,
                         "_in_savepoint must be cleared even when the "
                         "block raises — otherwise the next get_connection "
                         "skips its safety rollback forever")

    def test_in_savepoint_flag_set_during_block(self):
        observed = []

        def capture(query, params=None):
            observed.append(db._in_savepoint)
            return []

        with patch.object(db, "execute", capture):
            with db.savepoint("sp_2"):
                # Simulate a query inside the block. The auto-rollback
                # in get_connection() must be suppressed here, otherwise
                # an INERROR-state row failure would discard the whole
                # transaction.
                db.execute("SELECT 1")
            # After block: flag is reset.
        # The first call is SAVEPOINT itself (flag still False
        # because we set it AFTER execute returns), then the inner
        # SELECT (True), then RELEASE (still True).
        self.assertEqual(observed, [False, True, True])


class UpsertNaturalKeyTests(unittest.TestCase):
    """`_upsert_row` must look up by natural key when the incoming
    uuid doesn't match a server row, so two devices' independent
    uuids for the same logical cell don't trip the (task_id,
    column_id) UNIQUE constraint."""

    def test_marker_with_existing_natural_key_routes_to_update(self):
        # Server has marker id=cloud_id for (taskA, colB).
        # Client pushes id=client_id for the same (taskA, colB).
        # Expected: lookup by client_id misses; natural-key lookup
        # hits cloud_id; UPDATE the cloud row in place (do NOT
        # INSERT, which would have tripped the UNIQUE constraint).
        captured = {}

        def fake_execute_one(query, params=None):
            calls = captured.setdefault("selects", [])
            calls.append(params)
            # First call: lookup by id (`id = client_id`) — miss.
            if len(calls) == 1:
                return None
            # Second call: lookup by natural key
            # (`task_id = ? AND column_id = ?`) — hit, server has
            # cloud_id with an older timestamp than the incoming.
            return {
                "row_id": "cloud_id",
                "ts": _datetime("2026-05-01T00:00:00+00:00"),
                "deleted_at": None,
            }

        update_calls = []

        def fake_update(table, id_col, row_id, data, user_id, client_table):
            update_calls.append((table, id_col, row_id))
            return True

        insert_calls = []

        def fake_insert(*a, **kw):
            insert_calls.append(a)
            return True

        with patch.object(sync_push, "execute_one",
                          side_effect=fake_execute_one), \
             patch.object(sync_push, "_update_row", fake_update), \
             patch.object(sync_push, "_insert_row", fake_insert):
            ok = sync_push._upsert_row(
                table="markers",
                id_col="id",
                row_id="client_id",
                data={
                    "id": "client_id",
                    "task_id": "taskA",
                    "column_id": "colB",
                    "board_id": "boardZ",
                    "symbol": "dot",
                    "updated_at": 1777800000,
                },
                updated_at=_datetime("2026-05-02T00:00:00+00:00"),
                deleted=False,
                user_id=None,
                client_table="markers",
            )

        self.assertTrue(ok)
        self.assertEqual(insert_calls, [],
                         "Must NOT insert when natural key matches — "
                         "that's exactly what trips the UNIQUE constraint")
        self.assertEqual(len(update_calls), 1)
        # Critical: the update must target the CLOUD's id, not the
        # client's. Otherwise the WHERE clause matches nothing and
        # we silently no-op.
        self.assertEqual(update_calls[0][2], "cloud_id")

    def test_marker_with_no_existing_row_inserts(self):
        # Pure insert path — neither id nor natural key matches.
        with patch.object(sync_push, "execute_one", return_value=None), \
             patch.object(sync_push, "_insert_row",
                          return_value=True) as mock_insert, \
             patch.object(sync_push, "_update_row") as mock_update:
            ok = sync_push._upsert_row(
                table="markers",
                id_col="id",
                row_id="client_id",
                data={
                    "id": "client_id",
                    "task_id": "taskA",
                    "column_id": "colB",
                    "board_id": "boardZ",
                    "symbol": "dot",
                    "updated_at": 1777800000,
                },
                updated_at=_datetime("2026-05-02T00:00:00+00:00"),
                deleted=False,
                user_id=None,
                client_table="markers",
            )

        self.assertTrue(ok)
        mock_insert.assert_called_once()
        mock_update.assert_not_called()


def _datetime(iso):
    from datetime import datetime
    return datetime.fromisoformat(iso)


if __name__ == "__main__":
    unittest.main()
