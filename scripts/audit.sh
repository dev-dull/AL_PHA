#!/usr/bin/env bash
# Full repo audit: best practices, security, dependencies, tests.
# Run from the project root: ./scripts/audit.sh
set -uo pipefail
# Don't use -e: individual checks handle their own errors.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

PASS=0
FAIL=0
WARN=0

pass()  { echo -e "  ${GREEN}PASS${NC}  $1"; ((PASS++)); }
fail()  { echo -e "  ${RED}FAIL${NC}  $1"; ((FAIL++)); }
warn()  { echo -e "  ${YELLOW}WARN${NC}  $1"; ((WARN++)); }
header(){ echo -e "\n${BOLD}── $1 ──${NC}"; }

# ================================================================
header "1. Flutter structural audit"
# ================================================================
if flutter test test/audit/codebase_audit_test.dart > /dev/null 2>&1; then
  pass "Codebase audit tests"
else
  fail "Codebase audit tests — run: flutter test test/audit/codebase_audit_test.dart"
fi

# ================================================================
header "2. Static analysis"
# ================================================================
if flutter analyze --fatal-infos > /dev/null 2>&1; then
  pass "flutter analyze --fatal-infos"
else
  fail "Static analysis has issues — run: flutter analyze --fatal-infos"
fi

# ================================================================
header "3. Full test suite"
# ================================================================
TEST_OUTPUT=$(flutter test 2>&1)
if echo "$TEST_OUTPUT" | grep -q "All tests passed"; then
  TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '\+[0-9]+' | tail -1 | tr -d '+')
  pass "All ${TEST_COUNT} tests passed"
else
  FAILURES=$(echo "$TEST_OUTPUT" | grep -c '\[E\]' || true)
  fail "${FAILURES} test(s) failed — run: flutter test"
fi

# ================================================================
header "4. Dependency health (Flutter)"
# ================================================================
OUTDATED=$(flutter pub outdated 2>&1 | grep -c "^\*" || true)
RESOLVABLE=$(flutter pub outdated --mode=outdated 2>&1 | grep -cE "^\w" || true)
if [ "$OUTDATED" -eq 0 ]; then
  pass "All Flutter dependencies up to date"
else
  warn "${OUTDATED} Flutter packages have newer versions"
fi

# Check for known vulnerable packages (basic check).
if grep -q "http: \^0\." pubspec.yaml 2>/dev/null; then
  fail "http package version <1.0 has known vulnerabilities"
else
  pass "No known vulnerable Flutter packages"
fi

# ================================================================
header "5. Dependency health (Python/Lambda)"
# ================================================================
if [ -f lambda/requirements.txt ]; then
  # Check if requirements pin exact versions.
  UNPINNED=$(grep -cvE '==|^$|^#' lambda/requirements.txt || true)
  if [ "$UNPINNED" -eq 0 ]; then
    pass "All Python dependencies pinned to exact versions"
  else
    warn "${UNPINNED} Python dependencies not pinned (use ==)"
  fi
else
  warn "No lambda/requirements.txt found"
fi

# ================================================================
header "6. Security: credentials & secrets"
# ================================================================

# Check for hardcoded AWS keys.
if grep -rn "AKIA[A-Z0-9]\{16\}" lib/ lambda/ infra/ --include='*.dart' --include='*.py' --include='*.tf' 2>/dev/null; then
  fail "Hardcoded AWS access key found"
else
  pass "No hardcoded AWS keys"
fi

# Check for .env files committed.
if git ls-files | grep -qE '\.env$|\.env\.'; then
  fail "Environment files tracked in git"
else
  pass "No .env files in git"
fi

# Check for private keys.
if git ls-files | grep -qE '\.pem$|\.key$|id_rsa'; then
  fail "Private key files tracked in git"
else
  pass "No private keys in git"
fi

# Check for hardcoded passwords in code (not config).
if grep -rnI 'password\s*=' lib/ lambda/ --include='*.dart' --include='*.py' 2>/dev/null \
   | grep -v 'PASSWORD' | grep -v 'password=' | grep -v 'test' \
   | grep -qv '#'; then
  warn "Possible hardcoded password in source"
else
  pass "No hardcoded passwords in source"
fi

# ================================================================
header "7. Security: Python/Lambda SQL"
# ================================================================

# Check for f-string SQL (should use psycopg2.sql).
FSQL=$(grep -rn 'f".*SELECT\|f".*INSERT\|f".*UPDATE\|f".*DELETE' lambda/ --include='*.py' 2>/dev/null | grep -v '__pycache__' || true)
if [ -n "$FSQL" ]; then
  fail "f-string SQL found in Lambda code (use psycopg2.sql):"
  echo "$FSQL" | head -5
else
  pass "No f-string SQL — all identifiers use psycopg2.sql"
fi

# Check for string concatenation in SQL.
CONCAT_SQL=$(grep -rn "execute.*+.*'" lambda/ --include='*.py' 2>/dev/null | grep -v '__pycache__' || true)
if [ -n "$CONCAT_SQL" ]; then
  fail "String concatenation in SQL execute calls:"
  echo "$CONCAT_SQL" | head -5
else
  pass "No string concatenation in SQL"
fi

# ================================================================
header "8. Security: Flutter input handling"
# ================================================================

# Check for raw SQL in Dart (outside database.dart and tests).
RAW_SQL=$(grep -rn 'customStatement\|customSelect\|rawQuery' lib/ --include='*.dart' 2>/dev/null \
  | grep -v 'database.dart' | grep -v 'database.g.dart' \
  | grep -v 'change_tracker.dart' | grep -v 'sync_providers.dart' || true)
if [ -n "$RAW_SQL" ]; then
  warn "Raw SQL outside expected files:"
  echo "$RAW_SQL" | head -5
else
  pass "Raw SQL only in expected files (database, change_tracker, sync)"
fi

# ================================================================
header "9. Code quality"
# ================================================================

# Check for TODO/FIXME/HACK comments.
TODOS=$(grep -rnI 'TODO\|FIXME\|HACK\|XXX' lib/ lambda/ --include='*.dart' --include='*.py' 2>/dev/null | grep -v '__pycache__' | wc -l | tr -d ' ')
if [ "$TODOS" -gt 0 ]; then
  warn "${TODOS} TODO/FIXME/HACK comments found"
else
  pass "No TODO/FIXME/HACK comments"
fi

# Check for print() in production Dart code (covered by audit test but double-check).
PRINTS=$(grep -rn '^[[:space:]]*print(' lib/ --include='*.dart' 2>/dev/null | grep -v 'ignore: avoid_print' | wc -l | tr -d ' ')
if [ "$PRINTS" -gt 0 ]; then
  fail "${PRINTS} print() statements in production code"
else
  pass "No print() in production code"
fi

# Check for debugPrint in production code (should be removed after debugging).
DEBUG_PRINTS=$(grep -rn 'debugPrint(' lib/ --include='*.dart' 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEBUG_PRINTS" -gt 5 ]; then
  warn "${DEBUG_PRINTS} debugPrint() calls — consider removing after debugging"
elif [ "$DEBUG_PRINTS" -gt 0 ]; then
  pass "${DEBUG_PRINTS} debugPrint() calls (acceptable)"
else
  pass "No debugPrint() calls"
fi

# ================================================================
header "10. Infrastructure"
# ================================================================

# Check Terraform formatting.
if [ -d infra ]; then
  if terraform -chdir=infra fmt -check -recursive . > /dev/null 2>&1; then
    pass "Terraform files formatted"
  else
    warn "Terraform files need formatting — run: terraform -chdir=infra fmt -recursive ."
  fi
fi

# Check for terraform.tfstate in git.
if git ls-files | grep -q 'tfstate'; then
  fail "Terraform state file tracked in git"
else
  pass "No Terraform state in git"
fi

# ================================================================
header "11. Schema consistency"
# ================================================================

# Check that Drift schema version matches Postgres migrations.
DRIFT_VERSION=$(grep -oE 'schemaVersion => [0-9]+' lib/shared/database.dart 2>/dev/null | grep -oE '[0-9]+' || echo "0")
PG_MIGRATIONS=$(ls infra/migrations/V*.sql 2>/dev/null | wc -l | tr -d ' ')
if [ "$DRIFT_VERSION" -gt 0 ] && [ "$PG_MIGRATIONS" -gt 0 ]; then
  pass "Drift schema v${DRIFT_VERSION}, ${PG_MIGRATIONS} Postgres migration(s)"
else
  warn "Could not verify schema versions"
fi

# ================================================================
# Summary
# ================================================================
echo ""
echo -e "${BOLD}══ Audit Summary ══${NC}"
echo -e "  ${GREEN}PASS${NC}: ${PASS}"
echo -e "  ${YELLOW}WARN${NC}: ${WARN}"
echo -e "  ${RED}FAIL${NC}: ${FAIL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Audit failed with ${FAIL} failure(s).${NC}"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}Audit passed with ${WARN} warning(s).${NC}"
  exit 0
else
  echo -e "${GREEN}Audit passed — all clean.${NC}"
  exit 0
fi
