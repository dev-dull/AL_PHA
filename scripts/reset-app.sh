#!/usr/bin/env bash
# Reset planyr app data during local development.
#
# Usage:
#   scripts/reset-app.sh                # interactive: shows menu
#   scripts/reset-app.sh ios             # uninstall app from booted iOS sim
#   scripts/reset-app.sh ios-db          # wipe only the DB on booted iOS sim
#   scripts/reset-app.sh macos           # remove macOS app's local DB
#   scripts/reset-app.sh all             # all of the above
#
# After resetting:
#   - On next launch the welcome ("How It Works") dialog reappears
#   - Cloud sync state is gone (you'll need to sign in again on iOS)
#   - All boards / tasks / events / markers are wiped

set -euo pipefail

BUNDLE_ID="day.planyr.app"
MACOS_DB="$HOME/Library/Containers/$BUNDLE_ID/Data/Documents/planyr.db"

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

confirm() {
  # $1 = prompt; returns 0 if user confirms.
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

reset_ios_full() {
  local device
  device=$(xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c "import sys, json; d = json.load(sys.stdin)['devices']; \
print(next((x['udid'] for v in d.values() for x in v), ''))")
  if [[ -z "$device" ]]; then
    echo "  → no iOS simulator booted; skipping"
    return 0
  fi
  echo "  → uninstalling $BUNDLE_ID from sim $device"
  xcrun simctl uninstall "$device" "$BUNDLE_ID" 2>&1 \
    || echo "  → app wasn't installed (already clean)"
}

reset_ios_db_only() {
  local device app_dir
  device=$(xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c "import sys, json; d = json.load(sys.stdin)['devices']; \
print(next((x['udid'] for v in d.values() for x in v), ''))")
  if [[ -z "$device" ]]; then
    echo "  → no iOS simulator booted; skipping"
    return 0
  fi
  if ! app_dir=$(xcrun simctl get_app_container "$device" "$BUNDLE_ID" data 2>/dev/null); then
    echo "  → $BUNDLE_ID isn't installed on the sim; skipping"
    return 0
  fi
  local db="$app_dir/Documents/planyr.db"
  if [[ -f "$db" ]]; then
    rm "$db"
    echo "  → removed $db"
  else
    echo "  → no planyr.db at $db (already clean)"
  fi
}

reset_macos() {
  if [[ -f "$MACOS_DB" ]]; then
    rm "$MACOS_DB"
    echo "  → removed $MACOS_DB"
  else
    echo "  → no planyr.db at $MACOS_DB (already clean)"
  fi
}

interactive() {
  cat <<'EOF'
Pick a target:
  1) ios       — uninstall from booted iOS simulator (resets EVERYTHING)
  2) ios-db    — wipe only planyr.db on the iOS sim (keeps prefs/sync)
  3) macos     — remove macOS app's planyr.db
  4) all       — ios + macos
  q) quit
EOF
  read -r -p "> " choice
  case "$choice" in
    1|ios)     run ios ;;
    2|ios-db)  run ios-db ;;
    3|macos)   run macos ;;
    4|all)     run all ;;
    q|Q|"")    exit 0 ;;
    *)         echo "Unknown choice: $choice"; exit 1 ;;
  esac
}

run() {
  case "$1" in
    ios)
      echo "iOS simulator (full reset):"
      reset_ios_full
      ;;
    ios-db)
      echo "iOS simulator (DB only):"
      reset_ios_db_only
      ;;
    macos)
      echo "macOS:"
      reset_macos
      ;;
    all)
      echo "iOS simulator (full reset):"
      reset_ios_full
      echo "macOS:"
      reset_macos
      ;;
    *) usage 1 ;;
  esac
  echo "Done."
}

if [[ $# -eq 0 ]]; then
  interactive
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage 0
else
  run "$1"
fi
