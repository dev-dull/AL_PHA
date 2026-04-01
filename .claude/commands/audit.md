Run the project audit after code changes. Execute these in sequence, stopping if any fails:

1. `flutter test test/audit/codebase_audit_test.dart` — structural checks (repo fields, async callbacks, provider safety, tag sync, imports, schema, exports)
2. `flutter analyze --fatal-infos` — static analysis, zero tolerance
3. `flutter test` — full test suite (unit + smoke tests)

Report results of each step. If any step fails, show failure details and stop.
