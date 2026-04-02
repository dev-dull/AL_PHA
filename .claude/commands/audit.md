Run the full repo audit. Execute:

`./scripts/audit.sh`

This runs 11 audit categories:
1. Flutter structural audit (codebase_audit_test.dart)
2. Static analysis (flutter analyze --fatal-infos)
3. Full test suite
4. Dependency health (Flutter)
5. Dependency health (Python/Lambda)
6. Security: credentials & secrets
7. Security: Python/Lambda SQL injection
8. Security: Flutter input handling
9. Code quality (TODOs, print statements, debugPrint)
10. Infrastructure (Terraform formatting, state files)
11. Schema consistency (Drift vs Postgres)

Report the full output. If any FAIL items exist, show details and suggest fixes.
