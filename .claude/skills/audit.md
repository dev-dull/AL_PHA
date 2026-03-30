---
description: Run the codebase audit — checks for common bugs, then runs analyzer and full test suite.
user-invocable: true
---

Run the following three commands in sequence, stopping if any fails:

1. `flutter test test/audit/codebase_audit_test.dart` — structural audit checks (repository fields, async callbacks, provider safety, tag sync, imports, schema, exports)
2. `flutter analyze --fatal-infos` — static analysis with zero tolerance
3. `flutter test` — full test suite

Report the results of each step. If any step fails, show the failure details and stop.
