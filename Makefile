# Planyr — common build / test / run commands.
#
# Targets are .PHONY by default since none of them produce a stable
# named file at the project root. Output paths are documented per
# target.
#
# Starter set; flesh out under #46.

.PHONY: help apk apk-arm64 macos analyze test codegen clean clean-local-db

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / { \
		printf "  %-18s  %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)

# ─── Build ──────────────────────────────────────────────────────────

apk: ## Release APKs split per Android ABI (canonical: dogfood install).
	flutter build apk --release --split-per-abi
	@echo
	@echo "APKs:"
	@ls -lh build/app/outputs/flutter-apk/app-*-release.apk \
		2>/dev/null | awk '{print "  " $$NF "  (" $$5 ")"}'
	@echo
	@echo "Pixel + most modern Android: install app-arm64-v8a-release.apk"

apk-arm64: apk ## Path to the arm64 APK (most physical devices).
	@echo build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

macos: ## Release macOS .app bundle.
	flutter build macos --release
	@echo
	@echo "App: build/macos/Build/Products/Release/Planyr.app"

# ─── Quality gates ──────────────────────────────────────────────────

analyze: ## flutter analyze --fatal-infos. Exits non-zero on any issue.
	flutter analyze --fatal-infos

test: ## Run all Dart tests.
	flutter test

# ─── Codegen ────────────────────────────────────────────────────────

codegen: ## Re-run build_runner (Drift, Freezed, Riverpod). Run after
	## touching @freezed / @riverpod / Drift table classes.
	dart run build_runner build --delete-conflicting-outputs

# ─── Cleanup ────────────────────────────────────────────────────────

clean: ## flutter clean + drop build artifacts.
	flutter clean
	rm -rf build .dart_tool

clean-local-db: ## Wipe the macOS dev container's planyr.db (forces
	## the next launch to re-pull from cloud). DR runbook step 6.
	rm -f \
	  "$$HOME/Library/Containers/day.planyr.app/Data/Documents/planyr.db" \
	  "$$HOME/Library/Containers/day.planyr.app/Data/Documents/planyr.db-shm" \
	  "$$HOME/Library/Containers/day.planyr.app/Data/Documents/planyr.db-wal"
	@echo "Wiped local planyr.db. Launch the app to pull fresh from cloud."
