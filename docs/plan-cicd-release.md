# AlPHA — CI/CD and Release Strategy

## Overview

AlPHA (Alastair Planner & Habit App) is a Flutter application targeting Android, iOS, and Web, backed by AWS services. This document defines the complete CI/CD pipeline, multi-environment deployment strategy, release process, and operational practices.

---

## 1. CI/CD Platform: GitHub Actions

**Rationale:**

- **Native GitHub integration.** First-class PRs, branch protection, status checks, and deployments.
- **Matrix builds.** Excellent support for building Flutter across three platforms in parallel.
- **macOS runners.** iOS builds require macOS — available out of the box.
- **Marketplace ecosystem.** Pre-built actions for Flutter (`subosito/flutter-action`), AWS credentials, Fastlane, Firebase App Distribution.
- **Cost.** Free tier (2,000 min/month) covers initial development. macOS minutes cost 10x, so iOS builds should be optimized.
- **Secrets management.** Built-in encrypted secrets with environment-scoped access.

---

## 2. Branching Strategy: Trunk-Based Development

**Model:** Trunk-based development with short-lived feature branches and release branches.

### Branch Structure

| Branch | Purpose | Deploys To |
|---|---|---|
| `main` | Trunk. Always deployable. | Stage (automatically) |
| `feature/<ticket>-<description>` | Short-lived feature work | Dev (optional) |
| `fix/<ticket>-<description>` | Bug fixes | Dev (optional) |
| `release/<version>` | Release stabilization | Stage, then Prod |
| `hotfix/<ticket>-<description>` | Production emergency fixes | Stage, then Prod |

### Branch Naming Convention

```
feature/ALP-42-grid-view-horizontal-scroll
fix/ALP-108-marker-cycle-off-by-one
release/1.2.0
hotfix/ALP-201-crash-on-board-migration
```

### PR Workflow

1. Developer creates a feature branch from `main`.
2. Opens PR against `main` → triggers full CI pipeline.
3. Requires: all CI checks passing, at least one approval, no unresolved conversations.
4. Squash merge into `main`. Feature branch deleted automatically.
5. Merge triggers deployment to Test, then Stage.
6. For release: cut `release/<version>` from `main`. Final stabilization happens there.
7. After Prod release, release branch merged back to `main` and tagged.

### Dogfood Deployment

Triggered manually or on a nightly schedule from `main`.

---

## 3. CI Pipeline (Every PR)

### Job 1: Analysis & Linting (~2 min, `ubuntu-latest`)

```
- flutter pub get
- dart format --set-exit-if-changed .
- flutter analyze --fatal-infos
```

### Job 2: Unit & Widget Tests (~5 min, `ubuntu-latest`)

```
- flutter test --coverage
- Upload coverage to Codecov/Coveralls
- Fail if coverage drops below threshold
```

### Job 3: Golden/Visual Tests (~5 min, `ubuntu-latest`)

```
- flutter test --update-goldens=false --tags=golden
- If goldens fail, post visual diff comment on PR
```

### Job 4: Build Verification — Android (~8 min, `ubuntu-latest`)

```
- Setup Java 17
- flutter build apk --debug
```

### Job 5: Build Verification — iOS (~12 min, `macos-latest`)

```
- Setup Xcode (pinned version)
- flutter build ios --no-codesign --debug
```

**Cost optimization:** Only runs when `lib/`, `ios/`, `pubspec.*` files change.

### Job 6: Build Verification — Web (~3 min, `ubuntu-latest`)

```
- flutter build web --release
```

### Job 7: Backend Checks (~4 min, `ubuntu-latest`)

```
- Install dependencies
- Run linting + unit tests
- CDK synth (validate infrastructure)
```

### Path Filtering

- **Frontend jobs** trigger on: `lib/**`, `test/**`, `ios/**`, `android/**`, `web/**`, `pubspec.*`
- **Backend jobs** trigger on: `backend/**`, `infra/**`, `cdk/**`
- **Analysis/lint** always runs

---

## 4. CD Pipeline (Merge through Production)

```
PR merged to main
    │
    ├─► [Auto] Deploy backend to Test
    ├─► [Auto] Deploy web to Test
    ├─► [Auto] Build Android/iOS for Test
    │
    ├─► [Scheduled/Manual] Deploy to Dogfood
    │       ├── Android → Firebase App Distribution
    │       ├── iOS → TestFlight (internal group)
    │       └── Web → dogfood.alpha-app.com
    │
    ├─► [Release branch] Deploy to Stage
    │       ├── Full signed release builds
    │       ├── Smoke tests run automatically
    │       └── Manual QA sign-off required
    │
    └─► [Manual approval] Deploy to Prod
            ├── Android AAB → Google Play (Fastlane)
            ├── iOS IPA → App Store (Fastlane)
            ├── Web → Production CDN
            └── Backend → Production AWS
```

---

## 5. Multi-Environment Deployment

### 5.1 Dev (Local + Shared)

- Developers run `flutter run` locally against shared dev backend
- Backend deployed via CLI (`cdk deploy --context env=dev`)
- Local DynamoDB via Docker for offline work
- URL: `https://api-dev.alpha-app.com`

### 5.2 Test

- **Trigger:** Automatic on merge to `main`
- Builds verified, integration tests run against this backend
- Database seeded with test fixtures, clean state each deploy
- URL: `https://api-test.alpha-app.com`

### 5.3 Dogfood

- **Trigger:** Nightly schedule (2:00 AM UTC weekdays) or manual dispatch
- **Distribution:**
  - Android: Firebase App Distribution to internal tester group
  - iOS: TestFlight internal testing (up to 100 Apple IDs, no App Store Review)
  - Web: `https://dogfood.alpha-app.com` (Cognito-gated or IP-restricted)
- Dedicated AWS stack with real internal-only data
- In-app shake-to-report feedback mechanism
- URL: `https://api-dogfood.alpha-app.com`

### 5.4 Stage

- **Trigger:** Automatic when `release/*` branch pushed
- Mirrors production configuration (smaller instance sizes)
- Full release-signed builds, manual QA sign-off required
- URL: `https://api-stage.alpha-app.com`

### 5.5 Prod

- **Trigger:** Manual approval after Stage QA passes
- Submitted to Google Play + App Store via Fastlane
- Web deployed to `https://app.alpha-app.com`
- Deploy window: business hours, not Fridays
- URL: `https://api.alpha-app.com`

### Environment Matrix

| Aspect | Dev | Test | Dogfood | Stage | Prod |
|---|---|---|---|---|---|
| AWS Account | Shared dev | Shared dev | Separate | Separate | Separate |
| Database | Shared dev | Ephemeral/seeded | Persistent, internal | Sanitized prod-like | Production |
| App distribution | Local | CI-only | Firebase/TestFlight | TestFlight/Firebase | App Store/Play Store |
| Deploy trigger | Manual | Auto on merge | Nightly/manual | Auto on release branch | Manual approval |
| Monitoring | Minimal | CI logs | Sentry (dev DSN) | Sentry + CloudWatch | Full observability |

---

## 6. Flutter Build Matrix

### 6.1 Android

- Debug APK for Test/Dev
- Release APK for Dogfood/Firebase App Distribution
- Release AAB for Play Store submission
- `release.keystore` stored as base64 GitHub Actions secret
- `key.properties` generated at build time from secrets
- Environment config via `--dart-define-from-file=config/prod.json`

### 6.2 iOS

- No-codesign debug for PR verification
- Signed IPA for TestFlight via Fastlane Match
- Match profiles stored in private repo or S3
- Xcode version pinned in workflow

### 6.3 Web

- Release bundle: `flutter build web --release --web-renderer canvaskit`
- Deployed to S3, served via CloudFront
- Cache invalidation after each deploy

### Build Matrix in CI

```yaml
strategy:
  matrix:
    include:
      - platform: android
        runner: ubuntu-latest
        build-command: flutter build apk --release
      - platform: ios
        runner: macos-latest
        build-command: flutter build ipa --release
      - platform: web
        runner: ubuntu-latest
        build-command: flutter build web --release
```

---

## 7. AWS Backend Deployment

### 7.1 Infrastructure: AWS CDK (TypeScript)

CDK provides type-safe infrastructure, integrates natively with AWS, and allows shared constructs across environments.

### 7.2 Stack Structure

```
infra/
├── bin/alpha-app.ts
├── lib/
│   ├── alpha-api-stack.ts
│   ├── alpha-data-stack.ts
│   ├── alpha-web-stack.ts
│   └── alpha-monitoring-stack.ts
├── config/
│   ├── dev.ts / test.ts / dogfood.ts / stage.ts / prod.ts
```

### 7.3 Deployment

```
cdk deploy AlphaApi-${ENV} AlphaData-${ENV} --context env=${ENV}
```

### 7.4 Database Migrations

- DynamoDB: schema changes via CDK (table creation, GSI additions)
- Migrations always run before new code deploys
- Backward-compatible (expand-contract pattern)

### 7.5 Rollback Strategy

- **Lambda:** Revert by redeploying previous commit's CDK stack. Lambda aliases with weighted routing for canary deploys.
- **Database:** Never roll back destructive migrations. Use expand-contract pattern.
- **Automated:** CloudWatch alarm on 5xx > 5% for 5 min triggers auto-rollback.

---

## 8. Release Process

### 8.1 Versioning: Semver

`MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.

| Component | When to increment |
|---|---|
| MAJOR | Breaking changes, major redesigns |
| MINOR | New features |
| PATCH | Bug fixes, performance improvements |
| BUILD | Auto-incremented CI build number |

### 8.2 Changelog

- **Conventional Commits** enforced (`feat:`, `fix:`, `chore:`, etc.)
- Auto-generated via `git-cliff` or `conventional-changelog`
- Human-readable "What's New" written manually for app store notes

### 8.3 App Store Automation (Fastlane)

**Android (Google Play):**
- Tracks: `internal` (dogfood) → `alpha`/`beta` (stage) → `production`
- Staged rollout: 5% → 20% → 50% → 100%

**iOS (App Store):**
- TestFlight auto-upload
- App Store submission triggered manually after QA

### 8.4 Web Deployment

```
flutter build web --release --web-renderer canvaskit
aws s3 sync build/web/ s3://alpha-web-${ENV}/ --delete
aws cloudfront create-invalidation --distribution-id ${DIST_ID} --paths "/*"
```

### 8.5 Feature Flags (AWS AppConfig)

- Feature flags defined as JSON configuration profile
- Fetched at app startup, cached locally
- Percentage-based rollouts
- Quarterly flag cleanup to remove fully-rolled-out flags

### 8.6 Release Workflow (End to End)

1. Cut `release/1.3.0` branch from `main`
2. CI deploys to Stage automatically
3. Bump version, generate changelog
4. QA on Stage (all platforms)
5. Fixes go to release branch (cherry-picked to `main`)
6. After QA sign-off → trigger prod deployment (manual dispatch)
7. Backend CDK deploy, web S3/CloudFront deploy, app store uploads
8. Merge release branch back to `main`, tag `v1.3.0`
9. Create GitHub Release with changelog
10. Play Store rollout expanded over 3-5 days

---

## 9. Monitoring and Rollback

### 9.1 Crash Reporting: Sentry

- Unified across Flutter (all platforms) and backend
- Source maps + debug symbols uploaded in CI
- Release tracking tied to semver
- Performance monitoring with transaction tracing

### 9.2 Health Checks

| Layer | Health Check |
|---|---|
| API | `GET /health` returns 200 with dependency status |
| Web | CloudWatch Synthetics browser check |
| Database | Connection health, query latency metrics |
| Mobile | Startup crash rate, ANR rate via Sentry |

### 9.3 Alerting

- API 5xx > 5% over 5 min → P1
- API p99 > 3s over 10 min → P2
- Mobile crash rate > 2% sessions → P1
- Deployment health check fails → auto-rollback + P1

### 9.4 Rollback

- **Backend:** Lambda CodeDeploy with auto-rollback on CloudWatch alarms.
- **Web:** CloudFront origin switch to previous versioned S3 prefix.
- **Mobile:** Feature flags to disable broken features server-side. Halt staged rollout. Push hotfix.

---

## 10. Security

### 10.1 Secrets Management

| Secret | Storage |
|---|---|
| Android keystore | GitHub Actions secret (base64) |
| iOS certificates | Fastlane Match (private repo/S3) |
| App Store/Play Store keys | GitHub Actions secret |
| AWS credentials | GitHub OIDC with IAM role (no long-lived keys) |
| Sentry DSN | GitHub Actions secret (per env) |
| Database credentials | AWS Secrets Manager |

### 10.2 Code Signing

- **Android:** Dedicated release keystore. Consider Google Play App Signing.
- **iOS:** Fastlane Match with API key (not personal Apple ID).

### 10.3 Dependency Scanning

- `dart pub outdated` weekly + Dependabot/Renovate
- `osv-scanner` for vulnerability scanning in CI
- License compliance via `pana`
- `semgrep` for backend SAST

### 10.4 Additional Practices

- Branch protection on `main` and `release/*`
- No force pushes, require PR reviews
- SBOM generation per release

---

## Directory Structure for CI/CD Files

```
.github/
├── workflows/
│   ├── ci.yml                    # PR checks
│   ├── deploy-test.yml           # Deploy on merge to main
│   ├── deploy-dogfood.yml        # Nightly dogfood builds
│   ├── deploy-stage.yml          # Deploy on release branch
│   ├── deploy-prod.yml           # Production (manual trigger)
│   └── dependency-update.yml     # Renovate/Dependabot
├── actions/
│   ├── setup-flutter/            # Composite action
│   └── setup-signing/            # Composite action
fastlane/
├── Fastfile
├── Appfile
├── Matchfile
├── metadata/
│   ├── android/
│   └── ios/
infra/
├── bin/ / lib/ / config/
config/
├── dev.json / test.json / dogfood.json / stage.json / prod.json
```

---

## Implementation Sequencing

1. **Phase 1 (Week 1-2):** Basic CI — Flutter setup, analyze, test, build for all 3 platforms. Branch protection.
2. **Phase 2 (Week 3-4):** Backend CI — CDK synth, backend tests. AWS OIDC. Deploy to dev/test.
3. **Phase 3 (Week 5-6):** Dogfood pipeline — Fastlane, signing, Firebase App Distribution, TestFlight. Nightly builds.
4. **Phase 4 (Week 7-8):** Release pipeline — Stage/Prod workflows. Sentry. CloudWatch alarms. Rollback.
5. **Phase 5 (Week 9-10):** Polish — Feature flags, staged rollout, dependency scanning, golden tests, coverage gates.
