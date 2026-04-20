# AlPHA — DevOps Engineer Implementation Plan

## 1. Role & Responsibilities

### What DevOps Owns

| Domain | Scope |
|--------|-------|
| **Infrastructure** | All AWS resources: DynamoDB, AppSync, Cognito, Lambda, S3, CloudFront, EventBridge, CloudWatch, Secrets Manager. Provisioned via CDK. |
| **CI/CD Pipelines** | All GitHub Actions workflows (`ci.yml`, `deploy-test.yml`, `deploy-dogfood.yml`, `deploy-stage.yml`, `deploy-prod.yml`, `dependency-update.yml`). Pipeline maintenance, runner selection, caching, cost optimization. |
| **Environments** | Creation, configuration, isolation, teardown of dev, test, dogfood, stage, and prod environments. Environment-specific secrets, DNS, and certificates. |
| **Monitoring & Alerting** | CloudWatch dashboards, alarms, Synthetics canaries, Sentry project configuration, PagerDuty/Slack routing. |
| **Deployments** | Deployment automation, rollback procedures, canary/staged rollouts, release branch mechanics. |
| **Security** | IAM policies, OIDC federation, secrets management, WAF, branch protection, code signing infrastructure (keystore provisioning, Fastlane Match setup), dependency scanning in CI. |
| **Cost Management** | AWS Budgets, cost alerts, resource right-sizing, environment cleanup. |
| **Developer Experience** | Local development environment documentation, Docker Compose for local DynamoDB, environment variable contracts. |

### What DevOps Does NOT Own

| Domain | Owner |
|--------|-------|
| Application code (Flutter, Lambda resolver logic) | Software Engineer |
| Test authoring (unit, widget, integration, E2E) | QA Engineer / Software Engineer |
| UI/UX design, design tokens, component library | Product Designer |
| Product requirements and prioritization | Product Manager |
| GraphQL schema design | Software Engineer (DevOps reviews for infra impact) |
| Fastlane lane logic (build commands, metadata) | Software Engineer writes, DevOps integrates into CI |

### Shared Responsibilities

- **CDK stack structure**: DevOps owns the stacks; Software Engineer contributes Lambda function code that DevOps packages and deploys.
- **Test execution in CI**: DevOps builds the pipeline jobs; QA Engineer defines which tests run, thresholds, and tags.
- **Feature flags (AppConfig)**: DevOps provisions the AppConfig resource; Software Engineer manages flag definitions.

---

## 2. Infrastructure Setup Checklist

### 2.1 AWS Account Structure

**Recommendation: Multi-account with AWS Organizations (3 accounts)**

| Account | Environments Hosted | Justification |
|---------|---------------------|---------------|
| **alpha-dev** | dev, test | Shared development account. Lower blast radius. Free-tier eligible resources. Engineers may have console access. |
| **alpha-staging** | dogfood, stage | Pre-production. Mirrors prod configuration. Limited console access. |
| **alpha-prod** | prod | Production only. Strictest IAM. No direct console access except break-glass. |

**Why multi-account over single account with prefixes:**

1. **Blast radius isolation.** A misconfigured IAM policy or runaway Lambda in dev cannot affect prod data or availability.
2. **Cost attribution.** AWS Cost Explorer gives per-account breakdowns natively. No tagging discipline required.
3. **IAM boundary enforcement.** Service control policies (SCPs) at the Organization level prevent dev accounts from provisioning prod-grade resources or disabling CloudTrail.
4. **Compliance posture.** Separate accounts satisfy SOC 2 and similar frameworks' environment isolation requirements should AlPHA ever pursue them.
5. **AWS free tier.** Each account gets its own free tier allocation (25 GB DynamoDB, 1M Lambda requests, etc.), effectively tripling the free tier during development.

**Trade-off acknowledged:** Multi-account adds initial setup complexity (Organizations, cross-account IAM, CDK bootstrap per account). This is a one-time cost that pays off immediately in safety and clarity.

### 2.2 IAM Roles, Policies, and Permission Boundaries

| Role | Account | Purpose | Permissions |
|------|---------|---------|-------------|
| `alpha-github-actions-dev` | alpha-dev | CI/CD deployments to dev/test | CDK deploy, S3 sync, CloudFront invalidation, Lambda update, AppSync schema update. Scoped to `alpha-dev-*` and `alpha-test-*` resource prefixes. |
| `alpha-github-actions-staging` | alpha-staging | CI/CD deployments to dogfood/stage | Same as dev role but scoped to `alpha-dogfood-*` and `alpha-stage-*` prefixes. |
| `alpha-github-actions-prod` | alpha-prod | CI/CD deployments to prod | Same permissions, scoped to `alpha-prod-*`. Requires manual approval workflow before assumption. |
| `alpha-cdk-deploy` | Each account | CDK CloudFormation execution role | `AdministratorAccess` constrained by a permission boundary that denies IAM user creation, Organizations changes, and billing modifications. |
| `alpha-lambda-execution` | Each account | Lambda runtime role | DynamoDB read/write on `alpha-{env}-main`, CloudWatch Logs, Secrets Manager read, EventBridge put. |
| `alpha-appsync-service` | Each account | AppSync to invoke Lambda | Lambda invoke on `alpha-{env}-*` functions. |

**Permission Boundary (applied to all roles):**

```
Deny:
  - iam:CreateUser, iam:CreateAccessKey (no long-lived credentials)
  - organizations:* (no org changes)
  - account:* (no account-level changes)
  - aws-portal:* (no billing changes)
```

### 2.3 GitHub OIDC Federation with AWS

Steps for each AWS account:

1. Create an IAM OIDC Identity Provider with provider URL `https://token.actions.githubusercontent.com` and audience `sts.amazonaws.com`.
2. Create the `alpha-github-actions-{env}` role with trust policy:
   - Condition: `token.actions.githubusercontent.com:sub` matches `repo:alastairdrong/AlPHA:ref:refs/heads/main` (for deploy roles) or `repo:alastairdrong/AlPHA:*` (for CI read-only roles).
   - Condition: `token.actions.githubusercontent.com:aud` equals `sts.amazonaws.com`.
3. Attach the scoped policy and permission boundary.
4. Store the role ARN as a GitHub Actions environment secret (`AWS_ROLE_ARN_DEV`, `AWS_ROLE_ARN_STAGING`, `AWS_ROLE_ARN_PROD`).

**Zero long-lived AWS keys.** All CI/CD uses `aws-actions/configure-aws-credentials@v4` with OIDC.

### 2.4 CDK Bootstrap Per Account

For each account/region combination:

```bash
npx cdk bootstrap aws://<ACCOUNT_ID>/us-east-1 \
  --trust <GITHUB_ACTIONS_ROLE_ARN> \
  --cloudformation-execution-policies arn:aws:iam::<ACCOUNT_ID>:policy/alpha-cdk-execution-boundary \
  --qualifier alpha
```

Region recommendation: `us-east-1` (required for CloudFront certificates, simplifies initial setup; consider `eu-west-1` if GDPR is a concern post-launch).

### 2.5 DNS Setup

1. Register or transfer `alpha-app.com` (or chosen domain) to Route 53 in the prod account.
2. Create hosted zones:
   - `alpha-app.com` (prod account) -- NS records for subdomains delegated to other accounts.
   - `dev.alpha-app.com` (dev account) -- subdomain delegation.
   - `staging.alpha-app.com` (staging account) -- subdomain delegation.
3. Request ACM certificates (DNS validation):
   - `*.alpha-app.com` and `alpha-app.com` in prod account.
   - `*.dev.alpha-app.com` in dev account.
   - `*.staging.alpha-app.com` in staging account.
4. DNS records created by CDK stacks (CloudFront CNAME, AppSync CNAME).

### 2.6 Initial CDK Stack Deployment Order

Order matters due to cross-stack references:

```
1. data-stack     (DynamoDB table + GSIs -- no dependencies)
2. auth-stack     (Cognito User Pool -- no dependencies)
3. compute-stack  (Lambda functions -- depends on data-stack for table ARN, auth-stack for user pool)
4. api-stack      (AppSync API -- depends on compute-stack for Lambda ARNs, auth-stack for Cognito)
5. storage-stack  (S3 + CloudFront -- depends on api-stack for API URL in web config)
6. events-stack   (EventBridge rules -- depends on compute-stack for Lambda targets)
7. monitoring-stack (CloudWatch dashboards/alarms -- depends on all above for metric sources)
```

---

## 3. Sprint-by-Sprint Breakdown (12 Weeks, 2-Week Sprints)

### Sprint 1 (Weeks 1-2): Foundation

**Infrastructure:**
- Set up AWS Organizations with 3 accounts (alpha-dev, alpha-staging, alpha-prod).
- Configure IAM OIDC providers in all 3 accounts.
- Create IAM roles with permission boundaries.
- CDK bootstrap all 3 accounts.
- Initialize CDK project (`infra/` directory) with `data-stack` and `auth-stack`.
- Deploy `data-stack` and `auth-stack` to dev environment.
- Register domain, create hosted zones, request ACM certificates.

**CI/CD:**
- Create `ci.yml` -- full PR pipeline (lint, test, build verification for all 3 platforms).
- Create composite actions: `setup-flutter`, `setup-backend`.
- Configure branch protection on `main` (require CI pass, 1 approval, no force push).
- Set up GitHub repository secrets (AWS role ARNs, no long-lived keys).

**Environment Management:**
- Create `config/dev.json` with dev API endpoints and Cognito pool IDs.
- Document environment variable contract for Flutter app.

**Dependencies on Others:**
- Software Engineer: Flutter project must be initialized (`flutter create`) so CI can run `flutter analyze` and `flutter test`.
- Software Engineer: CDK project structure agreed upon.

**Deliverables:**
- [ ] 3 AWS accounts provisioned with OIDC federation.
- [ ] `ci.yml` runs successfully on PR.
- [ ] `data-stack` and `auth-stack` deployed to dev.
- [ ] Branch protection enforced on `main`.
- [ ] DNS zones and certificates provisioned.

---

### Sprint 2 (Weeks 3-4): Backend Deployment Pipeline

**Infrastructure:**
- Deploy `compute-stack`, `api-stack`, `storage-stack` to dev.
- Set up local DynamoDB via Docker Compose for developer experience.
- Create `deploy-test.yml` pipeline.

**CI/CD:**
- Create `deploy-test.yml` -- auto-deploy backend + web on merge to `main`.
- Add backend CI jobs to `ci.yml` (`cdk synth`, backend unit tests, lint).
- Implement path filtering in `ci.yml` (frontend jobs skip on `infra/**` changes and vice versa).
- Set up pub cache, Gradle, and CocoaPods caching in CI.

**Environment Management:**
- Deploy full stack to test environment.
- Create test database seeding script (Lambda or CLI).
- Document `api-test.alpha-app.com` endpoint for team.

**Dependencies on Others:**
- Software Engineer: Lambda resolver code for Phase 1 endpoints (createBoard, getBoard, listBoards, addTask, etc.).
- Software Engineer: GraphQL schema finalized for Phase 1.

**Deliverables:**
- [ ] Full backend stack deployed to dev and test.
- [ ] `deploy-test.yml` triggers on merge to `main` and completes in under 10 minutes.
- [ ] CI pipeline with path filtering, caching reduces build time by 30%+.
- [ ] Local DynamoDB Docker Compose documented in README.

---

### Sprint 3 (Weeks 5-6): Dogfood Pipeline

**Infrastructure:**
- Deploy full stack to dogfood environment (alpha-staging account).
- Configure CloudFront distribution for `dogfood.alpha-app.com`.
- Set up Cognito user pool for dogfood (separate from dev/test).

**CI/CD:**
- Create `deploy-dogfood.yml`:
  - Nightly schedule (2:00 AM UTC, weekdays).
  - Manual dispatch option.
  - Android: build release APK, upload to Firebase App Distribution.
  - iOS: build release IPA via Fastlane, upload to TestFlight (internal group).
  - Web: `flutter build web`, S3 sync, CloudFront invalidation.
  - Backend: CDK deploy to dogfood.
- Set up Fastlane:
  - Android: `release.keystore` stored as base64 GitHub secret, `key.properties` generated at build time.
  - iOS: Fastlane Match with S3 backend (private bucket in alpha-staging account). Provisioning profiles and certificates.
- Configure Firebase project for Android app distribution.

**Environment Management:**
- Dogfood environment fully operational.
- Team members install dogfood builds (Android: Firebase tester group invite, iOS: TestFlight internal).
- Shake-to-report feedback mechanism: configure Sentry with dogfood DSN.

**Dependencies on Others:**
- Software Engineer: Fastlane `Fastfile` lane definitions for Android and iOS builds.
- Software Engineer: `--dart-define-from-file` config files per environment.
- QA Engineer: (none yet, but inform about dogfood availability).

**Deliverables:**
- [ ] Nightly dogfood builds delivered to team via Firebase App Distribution (Android) and TestFlight (iOS).
- [ ] `dogfood.alpha-app.com` serves web build.
- [ ] Dogfood backend fully operational at `api-dogfood.alpha-app.com`.
- [ ] Code signing working for both platforms in CI.
- [ ] Team actively installing and using dogfood builds.

---

### Sprint 4 (Weeks 7-8): Stage & Release Pipeline

**Infrastructure:**
- Deploy full stack to stage environment (alpha-staging account).
- Deploy `events-stack` to dev, test, dogfood, stage (EventBridge rules for migration reminders, recurring tasks).
- Configure AppSync caching per stage config.

**CI/CD:**
- Create `deploy-stage.yml`:
  - Triggers on `release/*` branch push.
  - Full signed release builds (Android AAB, iOS IPA, Web).
  - Backend CDK deploy to stage.
  - Post-deploy smoke tests (GraphQL health check, web load test).
- Create `deploy-prod.yml` (skeleton with manual approval gate; full implementation in Sprint 5).
- Add `dependency-update.yml` with Renovate or Dependabot configuration.
- Add `osv-scanner` and `semgrep` to CI pipeline.

**Environment Management:**
- Stage mirrors prod configuration (smaller capacity).
- Stage database: sanitized prod-like data (initially seeded, later snapshot from dogfood).

**Dependencies on Others:**
- Software Engineer: Release branch workflow documented.
- QA Engineer: QA sign-off process defined for stage.

**Deliverables:**
- [ ] `deploy-stage.yml` triggers on `release/*` push, builds all platforms, deploys backend.
- [ ] `deploy-prod.yml` skeleton with manual approval step.
- [ ] Dependency scanning runs on every PR.
- [ ] Stage environment fully operational at `api-stage.alpha-app.com`.

---

### Sprint 5 (Weeks 9-10): Production & Monitoring

**Infrastructure:**
- Deploy full stack to prod (alpha-prod account).
- Deploy `monitoring-stack` to all environments.
- Configure CloudWatch dashboards (see Section 6).
- Configure CloudWatch alarms (see Section 6).
- Set up CloudWatch Synthetics canary for prod.
- Configure WAF on AppSync/CloudFront (rate limiting, geo-blocking if needed).

**CI/CD:**
- Complete `deploy-prod.yml`:
  - Manual workflow dispatch with version input.
  - Require GitHub environment approval (2 approvers).
  - Backend CDK deploy to prod.
  - Web S3 sync + CloudFront invalidation to prod.
  - Android AAB upload to Google Play via Fastlane (internal track first).
  - iOS IPA upload to App Store Connect via Fastlane.
  - Post-deploy smoke tests.
  - Automated rollback on CloudWatch alarm trigger.
- Implement Lambda alias-based canary deployment (10% traffic for 10 min, then full).

**Environment Management:**
- Prod environment fully operational.
- DynamoDB point-in-time recovery enabled on prod.
- S3 versioning enabled on prod web bucket.

**Dependencies on Others:**
- Software Engineer: App Store / Play Store accounts set up, app listing metadata.
- QA Engineer: Smoke test definitions for prod.

**Deliverables:**
- [ ] Prod environment live at `api.alpha-app.com` and `app.alpha-app.com`.
- [ ] Full prod deployment pipeline with manual approval, canary, and rollback.
- [ ] CloudWatch dashboards and alarms operational.
- [ ] WAF configured on prod API and CDN.
- [ ] DynamoDB PITR and S3 versioning enabled.

---

### Sprint 6 (Weeks 11-12): Hardening & Documentation

**Infrastructure:**
- DynamoDB on-demand capacity review; right-size Lambda memory based on X-Ray traces.
- Enable AWS CloudTrail in all accounts.
- Configure AWS Config rules for compliance checks.
- Set up AWS Budgets with alerts at $50, $100, $200/month per account.

**CI/CD:**
- Performance optimization: parallel job execution, build artifact reuse between jobs.
- CI time target: PR pipeline under 12 minutes, deploy pipelines under 15 minutes.
- Golden test update workflow (generate on Linux, commit via bot PR).
- SBOM generation added to release pipeline.

**Environment Management:**
- Automated test environment cleanup (nightly Lambda to purge stale test user data).
- Environment variable audit across all environments.

**Dependencies on Others:**
- QA Engineer: Integration test and E2E test jobs finalized for CI.
- Software Engineer: Performance benchmarks from dogfood usage.

**Deliverables:**
- [ ] Incident response runbook documented.
- [ ] Cost monitoring operational with budget alerts.
- [ ] All 5 pipelines tested end-to-end.
- [ ] CI execution times within targets.
- [ ] CloudTrail and AWS Config enabled.
- [ ] Full DevOps documentation (runbooks, architecture diagrams, onboarding guide).

---

## 4. CI/CD Pipeline Specifications

### 4.a PR Pipeline (`ci.yml`)

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  
concurrency:
  group: ci-${{ github.head_ref }}
  cancel-in-progress: true

jobs:
  analyze:
    # ~2 min | ubuntu-latest | Always runs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter  # composite: installs Flutter, restores pub cache
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze --fatal-infos

  unit-tests:
    # ~5 min | ubuntu-latest | Always runs
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          fail_ci_if_error: true
      # Fail if coverage below 80%

  golden-tests:
    # ~5 min | ubuntu-latest | Runs on lib/** or test/** changes
    runs-on: ubuntu-latest
    needs: analyze
    if: contains(github.event.pull_request.changed_files_paths, 'lib/') || contains(...)
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - run: flutter test --tags=golden
      # On failure: post visual diff as PR comment

  build-android:
    # ~8 min | ubuntu-latest | Path filter: lib/, android/, pubspec.*
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ hashFiles('android/build.gradle', 'android/app/build.gradle') }}
      - run: flutter build apk --debug

  build-ios:
    # ~12 min | macos-14 (M1) | Path filter: lib/, ios/, pubspec.*
    runs-on: macos-14
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: actions/cache@v4
        with:
          path: ios/Pods
          key: pods-${{ hashFiles('ios/Podfile.lock') }}
      - run: flutter build ios --no-codesign --debug

  build-web:
    # ~3 min | ubuntu-latest | Path filter: lib/, web/, pubspec.*
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - run: flutter build web --release

  backend-checks:
    # ~4 min | ubuntu-latest | Path filter: infra/**, lambda/**
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: actions/cache@v4
        with:
          path: infra/node_modules
          key: npm-${{ hashFiles('infra/package-lock.json') }}
      - run: cd infra && npm ci
      - run: cd infra && npm run lint
      - run: cd infra && npm test
      - run: cd infra && npx cdk synth --context env=dev
```

**Path filtering** is implemented via `dorny/paths-filter@v3` or GitHub's native `paths` key on the `on.pull_request` trigger. The `analyze` and `unit-tests` jobs always run. Platform build jobs and backend checks use path filters.

**Caching strategy:**
- Flutter pub cache: `~/.pub-cache` keyed on `pubspec.lock` hash.
- Gradle: `~/.gradle/caches` + `~/.gradle/wrapper` keyed on `build.gradle` hash.
- CocoaPods: `ios/Pods` keyed on `Podfile.lock` hash.
- Node modules: `infra/node_modules` keyed on `package-lock.json` hash.

**Concurrency:** One CI run per PR head branch. New pushes cancel in-progress runs.

**Estimated total time:** ~12 minutes (longest path: `analyze` 2 min + `build-ios` 12 min = 14 min worst case; most paths finish in 8-10 min).

---

### 4.b Test Deploy Pipeline (`deploy-test.yml`)

```yaml
name: Deploy to Test
on:
  push:
    branches: [main]

concurrency:
  group: deploy-test
  cancel-in-progress: false  # Complete in-progress deploys

jobs:
  deploy-backend:
    # ~8 min
    runs-on: ubuntu-latest
    environment: test
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEV }}
          aws-region: us-east-1
      - run: cd infra && npm ci
      - run: cd infra && npx cdk deploy --all --context env=test --require-approval never
      - name: Seed test data
        run: cd infra && npx ts-node scripts/seed-test-data.ts --env test

  deploy-web:
    # ~5 min
    runs-on: ubuntu-latest
    needs: deploy-backend
    environment: test
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEV }}
          aws-region: us-east-1
      - run: flutter build web --release --dart-define-from-file=config/test.json
      - run: aws s3 sync build/web/ s3://alpha-test-web/ --delete
      - run: aws cloudfront create-invalidation --distribution-id ${{ vars.CF_DIST_ID_TEST }} --paths "/*"

  smoke-tests:
    # ~3 min
    runs-on: ubuntu-latest
    needs: [deploy-backend, deploy-web]
    steps:
      - uses: actions/checkout@v4
      - name: GraphQL health check
        run: |
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST https://api-test.alpha-app.com/graphql \
            -H "Content-Type: application/json" \
            -d '{"query":"{ listTemplates { name } }"}')
          [ "$STATUS" -eq 200 ] || exit 1
      - name: Web health check
        run: |
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://test.alpha-app.com)
          [ "$STATUS" -eq 200 ] || exit 1
```

---

### 4.c Dogfood Pipeline (`deploy-dogfood.yml`)

```yaml
name: Deploy to Dogfood
on:
  schedule:
    - cron: '0 2 * * 1-5'  # 2:00 AM UTC, Mon-Fri
  workflow_dispatch:        # Manual trigger

concurrency:
  group: deploy-dogfood
  cancel-in-progress: false

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    environment: dogfood
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1
      - run: cd infra && npm ci
      - run: cd infra && npx cdk deploy --all --context env=dogfood --require-approval never

  build-android:
    runs-on: ubuntu-latest
    needs: deploy-backend
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: ./.github/actions/setup-signing  # Decodes keystore from secret, writes key.properties
      - run: flutter build apk --release --dart-define-from-file=config/dogfood.json
      - uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: alpha-team
          file: build/app/outputs/flutter-apk/app-release.apk
          releaseNotes: "Dogfood build ${{ github.sha }}"

  build-ios:
    runs-on: macos-14
    needs: deploy-backend
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - name: Install Fastlane
        run: gem install fastlane
      - name: Fastlane Match (fetch certs)
        run: cd ios && fastlane match appstore --readonly
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_S3_BUCKET: ${{ secrets.MATCH_S3_BUCKET }}
          MATCH_S3_REGION: us-east-1
      - run: flutter build ipa --release --dart-define-from-file=config/dogfood.json
      - name: Upload to TestFlight
        run: cd ios && fastlane pilot upload --skip_waiting_for_build_processing
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_KEY }}

  deploy-web:
    runs-on: ubuntu-latest
    needs: deploy-backend
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1
      - run: flutter build web --release --dart-define-from-file=config/dogfood.json
      - run: aws s3 sync build/web/ s3://alpha-dogfood-web/ --delete
      - run: aws cloudfront create-invalidation --distribution-id ${{ vars.CF_DIST_ID_DOGFOOD }} --paths "/*"

  notify:
    runs-on: ubuntu-latest
    needs: [build-android, build-ios, deploy-web]
    if: always()
    steps:
      - uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Dogfood build ${{ needs.build-android.result == 'success' && needs.build-ios.result == 'success' && 'ready' || 'failed' }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

**How developers install dogfood builds:**
- **Android:** Accept Firebase App Distribution invite email. Install the Firebase App Tester app. New builds appear automatically with install prompt.
- **iOS:** Added to TestFlight internal testing group (via Apple ID). TestFlight app shows new builds automatically. No App Store Review required for internal testing (up to 100 testers).
- **Web:** Navigate to `https://dogfood.alpha-app.com`. Access gated by Cognito authentication (dogfood user pool).

---

### 4.d Stage Pipeline (`deploy-stage.yml`)

```yaml
name: Deploy to Stage
on:
  push:
    branches: ['release/**']

concurrency:
  group: deploy-stage
  cancel-in-progress: false

jobs:
  ci-checks:
    # Re-run full CI suite on the release branch
    uses: ./.github/workflows/ci.yml

  deploy-backend:
    runs-on: ubuntu-latest
    needs: ci-checks
    environment: stage
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1
      - run: cd infra && npm ci
      - run: cd infra && npx cdk deploy --all --context env=stage --require-approval never

  build-android:
    runs-on: ubuntu-latest
    needs: ci-checks
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: ./.github/actions/setup-signing
      - run: flutter build appbundle --release --dart-define-from-file=config/stage.json
      - uses: actions/upload-artifact@v4
        with:
          name: android-aab-stage
          path: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-14
    needs: ci-checks
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - run: gem install fastlane
      - run: cd ios && fastlane match appstore --readonly
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_S3_BUCKET: ${{ secrets.MATCH_S3_BUCKET }}
      - run: flutter build ipa --release --dart-define-from-file=config/stage.json --export-options-plist=ios/ExportOptions.plist
      - uses: actions/upload-artifact@v4
        with:
          name: ios-ipa-stage
          path: build/ios/ipa/*.ipa

  build-web:
    runs-on: ubuntu-latest
    needs: ci-checks
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-flutter
      - run: flutter build web --release --dart-define-from-file=config/stage.json
      - uses: actions/upload-artifact@v4
        with:
          name: web-stage
          path: build/web/

  deploy-stage:
    runs-on: ubuntu-latest
    needs: [deploy-backend, build-android, build-ios, build-web]
    environment: stage
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1
      - uses: actions/download-artifact@v4
        with: { name: web-stage, path: web-build/ }
      - run: aws s3 sync web-build/ s3://alpha-stage-web/ --delete
      - run: aws cloudfront create-invalidation --distribution-id ${{ vars.CF_DIST_ID_STAGE }} --paths "/*"

  smoke-tests:
    runs-on: ubuntu-latest
    needs: deploy-stage
    steps:
      - uses: actions/checkout@v4
      - name: API smoke test
        run: |
          curl -sf https://api-stage.alpha-app.com/graphql \
            -X POST -H "Content-Type: application/json" \
            -d '{"query":"{ listTemplates { name } }"}'
      - name: Web smoke test
        run: curl -sf https://stage.alpha-app.com

  # QA GATE: Stage environment requires manual approval before prod deploy.
  # QA Engineer reviews builds, runs E2E tests, then approves in GitHub.
```

---

### 4.e Prod Pipeline (`deploy-prod.yml`)

```yaml
name: Deploy to Production
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., 1.3.0)'
        required: true
      skip-mobile-upload:
        description: 'Skip app store uploads (backend/web only)'
        type: boolean
        default: false

concurrency:
  group: deploy-prod
  cancel-in-progress: false

jobs:
  approval-gate:
    runs-on: ubuntu-latest
    environment: production  # Requires 2 approvers configured in GitHub environment settings
    steps:
      - run: echo "Deploying version ${{ inputs.version }} to production"

  deploy-backend:
    runs-on: ubuntu-latest
    needs: approval-gate
    environment: production
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          ref: release/${{ inputs.version }}
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: us-east-1
      - run: cd infra && npm ci
      - run: cd infra && npx cdk deploy --all --context env=prod --require-approval never
      # CDK uses Lambda aliases with CodeDeploy for canary (10% -> 100% over 10 min)

  deploy-web:
    runs-on: ubuntu-latest
    needs: approval-gate
    environment: production
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          ref: release/${{ inputs.version }}
      - uses: ./.github/actions/setup-flutter
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: us-east-1
      - run: flutter build web --release --dart-define-from-file=config/prod.json
      # Deploy to versioned S3 prefix for rollback capability
      - run: aws s3 sync build/web/ s3://alpha-prod-web/v${{ inputs.version }}/ --delete
      - run: aws s3 sync build/web/ s3://alpha-prod-web/latest/ --delete
      - run: aws cloudfront create-invalidation --distribution-id ${{ vars.CF_DIST_ID_PROD }} --paths "/*"

  upload-android:
    if: ${{ !inputs.skip-mobile-upload }}
    runs-on: ubuntu-latest
    needs: approval-gate
    steps:
      - uses: actions/checkout@v4
        with:
          ref: release/${{ inputs.version }}
      - uses: ./.github/actions/setup-flutter
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - uses: ./.github/actions/setup-signing
      - run: flutter build appbundle --release --dart-define-from-file=config/prod.json --build-number=${{ github.run_number }}
      - run: gem install fastlane
      - run: cd android && fastlane supply --aab ../build/app/outputs/bundle/release/app-release.aab --track internal
        env:
          SUPPLY_JSON_KEY_DATA: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
      # Staged rollout: start at internal track, manually promote to production at 5% -> 20% -> 100%

  upload-ios:
    if: ${{ !inputs.skip-mobile-upload }}
    runs-on: macos-14
    needs: approval-gate
    steps:
      - uses: actions/checkout@v4
        with:
          ref: release/${{ inputs.version }}
      - uses: ./.github/actions/setup-flutter
      - run: gem install fastlane
      - run: cd ios && fastlane match appstore --readonly
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_S3_BUCKET: ${{ secrets.MATCH_S3_BUCKET }}
      - run: flutter build ipa --release --dart-define-from-file=config/prod.json --build-number=${{ github.run_number }} --export-options-plist=ios/ExportOptions.plist
      - run: cd ios && fastlane deliver --ipa ../build/ios/ipa/AlPHA.ipa --skip_metadata --skip_screenshots
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_KEY }}

  post-deploy-validation:
    runs-on: ubuntu-latest
    needs: [deploy-backend, deploy-web]
    steps:
      - uses: actions/checkout@v4
      - name: API health check
        run: |
          for i in 1 2 3 4 5; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
              -X POST https://api.alpha-app.com/graphql \
              -H "Content-Type: application/json" \
              -d '{"query":"{ listTemplates { name } }"}')
            [ "$STATUS" -eq 200 ] && exit 0
            sleep 10
          done
          exit 1
      - name: Web health check
        run: curl -sf https://app.alpha-app.com
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: '{"text": "v${{ inputs.version }} deployed to production"}'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

  tag-release:
    runs-on: ubuntu-latest
    needs: post-deploy-validation
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: release/${{ inputs.version }}
      - run: git tag v${{ inputs.version }}
      - run: git push origin v${{ inputs.version }}
      - name: Create GitHub Release
        run: |
          gh release create v${{ inputs.version }} \
            --title "v${{ inputs.version }}" \
            --generate-notes
        env:
          GH_TOKEN: ${{ github.token }}
```

**Rollback procedure (manual):**

```bash
# Backend: redeploy previous version's CDK stack
git checkout release/<previous-version>
cd infra && npx cdk deploy --all --context env=prod --require-approval never

# Web: switch CloudFront origin to previous versioned S3 prefix
aws s3 sync s3://alpha-prod-web/v<previous-version>/ s3://alpha-prod-web/latest/ --delete
aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"

# Mobile: halt staged rollout in Play Console / App Store Connect
# Enable feature flags to disable broken functionality server-side
```

---

## 5. Environment Management

### 5.1 Environment Matrix

| Resource | Dev | Test | Dogfood | Stage | Prod |
|----------|-----|------|---------|-------|------|
| **AWS Account** | alpha-dev | alpha-dev | alpha-staging | alpha-staging | alpha-prod |
| **DynamoDB Table** | `alpha-dev-main` | `alpha-test-main` | `alpha-dogfood-main` | `alpha-stage-main` | `alpha-prod-main` |
| **DynamoDB Billing** | On-demand | On-demand | On-demand | On-demand | On-demand (review at scale) |
| **DynamoDB PITR** | Off | Off | Off | On | On |
| **AppSync API** | `alpha-dev-api` | `alpha-test-api` | `alpha-dogfood-api` | `alpha-stage-api` | `alpha-prod-api` |
| **AppSync Cache** | Off (0s TTL) | Off | 60s TTL | 60s TTL | 300s TTL |
| **Cognito Pool** | `alpha-dev-users` | `alpha-test-users` | `alpha-dogfood-users` | `alpha-stage-users` | `alpha-prod-users` |
| **S3 Web Bucket** | `alpha-dev-web` | `alpha-test-web` | `alpha-dogfood-web` | `alpha-stage-web` | `alpha-prod-web` |
| **S3 Versioning** | Off | Off | Off | On | On |
| **CloudFront** | Optional | Optional | Yes | Yes | Yes |
| **Lambda Memory** | 256 MB | 256 MB | 256 MB | 512 MB | 512 MB |
| **Lambda Concurrency** | 10 | 10 | 20 | 50 | 100 (per function) |
| **Log Retention** | 7 days | 3 days | 14 days | 30 days | 90 days |
| **CloudWatch Alarms** | None | None | Basic | Full | Full + auto-rollback |
| **WAF** | None | None | None | None | Yes |
| **EventBridge Rules** | Active | Active | Active | Active | Active |

### 5.2 Environment Variables and Configuration

Each environment uses a `config/{env}.json` file consumed by `--dart-define-from-file`:

```json
{
  "API_URL": "https://api-{env}.alpha-app.com/graphql",
  "COGNITO_USER_POOL_ID": "us-east-1_XXXXXXX",
  "COGNITO_CLIENT_ID": "xxxxxxxxxxxxxxxxxxxxxxxxx",
  "COGNITO_REGION": "us-east-1",
  "SENTRY_DSN": "https://xxx@sentry.io/yyy",
  "ENVIRONMENT": "{env}",
  "APPCONFIG_APP_ID": "xxxxxxxxx",
  "APPCONFIG_PROFILE_ID": "xxxxxxxxx"
}
```

These files are checked into the repo (no secrets). Secrets are injected at build time from GitHub Actions secrets.

### 5.3 Data Management

| Environment | Data Strategy |
|-------------|---------------|
| **Dev** | Shared, persistent. Developers create their own test data. No automated cleanup. |
| **Test** | Ephemeral. Seeded with fixtures on each deploy. Cleanup Lambda runs post-integration-tests. |
| **Dogfood** | Persistent, real usage. Team members use it as their actual planner. Never wiped. Backed up weekly. |
| **Stage** | Seeded with sanitized data resembling prod patterns. Refreshed on each release branch deploy. |
| **Prod** | Production data. PITR enabled. On-demand backups before each deployment. |

### 5.4 Access Control

| Environment | Who Can Deploy | Who Has Console Access | Who Has Data Access |
|-------------|---------------|----------------------|-------------------|
| **Dev** | Any engineer (merge to `main`) | All engineers | All engineers |
| **Test** | Automated (on merge) | All engineers | All engineers |
| **Dogfood** | Automated (nightly) or manual dispatch by any engineer | DevOps, Tech Lead | DevOps (data contains real team usage) |
| **Stage** | Automated (on release branch push) | DevOps, Tech Lead, QA | DevOps, QA |
| **Prod** | Manual approval (2 approvers: Tech Lead + DevOps) | DevOps (break-glass only) | DevOps (break-glass only, audited) |

---

## 6. Monitoring & Alerting Setup

### 6.1 CloudWatch Dashboards

**Dashboard: "AlPHA-{env}-Overview"** (one per environment with alarms, deployed via monitoring-stack)

| Widget | Metric Source | Visualization |
|--------|---------------|---------------|
| API Request Count | AppSync `4XXError` + `5XXError` + `2XXSuccess` | Stacked area, 5-min periods |
| API Latency | AppSync `Latency` | Line chart with p50, p95, p99 statistics |
| API Error Rate | `5XXError / (5XXError + 2XXSuccess) * 100` | Number widget (current) + line chart (24h) |
| Lambda Invocations | Lambda `Invocations` per function | Stacked bar |
| Lambda Duration | Lambda `Duration` per function | Line chart with p50, p95, p99 |
| Lambda Errors | Lambda `Errors` per function | Number widget + line chart |
| Lambda Cold Starts | Lambda `Init Duration` count | Line chart |
| DynamoDB Read Capacity | DynamoDB `ConsumedReadCapacityUnits` | Line chart |
| DynamoDB Write Capacity | DynamoDB `ConsumedWriteCapacityUnits` | Line chart |
| DynamoDB Throttles | DynamoDB `ThrottledRequests` | Number widget (should be 0) |
| Cognito Sign-ins | Cognito `SignInSuccesses` | Line chart |
| CloudFront Requests | CloudFront `Requests` | Line chart |
| CloudFront Error Rate | CloudFront `4xxErrorRate` + `5xxErrorRate` | Line chart |

### 6.2 CloudWatch Alarms

| Alarm | Metric | Threshold | Period | Evaluation Periods | Severity | Action |
|-------|--------|-----------|--------|-------------------|----------|--------|
| API High Error Rate | AppSync `5XXError` rate | > 1% | 5 min | 2 consecutive | P1 | SNS -> PagerDuty + Slack |
| API Very High Error Rate | AppSync `5XXError` rate | > 5% | 5 min | 1 | P0 | SNS -> PagerDuty + auto-rollback (prod) |
| API High Latency | AppSync `Latency` p99 | > 2000 ms | 5 min | 3 consecutive | P2 | SNS -> Slack |
| API Critical Latency | AppSync `Latency` p99 | > 5000 ms | 5 min | 2 consecutive | P1 | SNS -> PagerDuty |
| Lambda High Error Rate | Lambda `Errors` / `Invocations` | > 5% | 5 min | 2 consecutive | P1 | SNS -> PagerDuty |
| Lambda High Duration | Lambda `Duration` p99 | > 5000 ms | 5 min | 3 consecutive | P2 | SNS -> Slack |
| DynamoDB Throttling | DynamoDB `ThrottledRequests` | > 0 | 1 min | 3 consecutive | P2 | SNS -> Slack |
| DynamoDB High Capacity | DynamoDB `ConsumedReadCapacityUnits` | > 80% of account limit | 15 min | 2 consecutive | P2 | SNS -> Slack |
| Cognito Failed Sign-ins | Cognito `SignInFailures` | > 50 in 5 min | 5 min | 1 | P3 | SNS -> Slack (possible brute force) |

### 6.3 Sentry Integration

- **Flutter SDK** integrated in the app with DSN per environment.
- **Sentry for Lambda** using `@sentry/serverless` wrapper on each Lambda handler.
- Source maps (web) and debug symbols (Android/iOS) uploaded in CI during release builds.
- Release version tracking tied to `pubspec.yaml` version.
- Performance monitoring enabled with 20% sample rate (prod), 100% (dogfood/stage).
- Alert rules: crash-free sessions < 99% triggers P1.

### 6.4 CloudWatch Synthetics (Uptime Monitoring)

A Synthetics canary runs every 5 minutes on prod:

1. Load `https://app.alpha-app.com` -- assert 200 and page title contains "AlPHA".
2. POST to `https://api.alpha-app.com/graphql` with `{ listTemplates { name } }` -- assert 200 and response contains template data.
3. Failure triggers P1 alarm.

### 6.5 Alert Routing

| Severity | Channel | Response Time |
|----------|---------|---------------|
| P0 | PagerDuty (phone call) + Slack #alpha-incidents | 15 minutes |
| P1 | PagerDuty (push notification) + Slack #alpha-incidents | 1 hour |
| P2 | Slack #alpha-alerts | 4 hours (business hours) |
| P3 | Slack #alpha-alerts | Next business day |

---

## 7. Security Implementation

### 7.1 Secrets Management

| Secret | Storage Location | Rotation |
|--------|-----------------|----------|
| AWS IAM credentials | None (OIDC federation, no keys) | N/A |
| Android release keystore (base64) | GitHub Actions secret `ANDROID_KEYSTORE` | On compromise only |
| Android keystore password | GitHub Actions secret `ANDROID_KEYSTORE_PASSWORD` | On compromise only |
| iOS certificates + profiles | Fastlane Match S3 bucket (encrypted) | Annual (Apple requirement) |
| Fastlane Match encryption password | GitHub Actions secret `MATCH_PASSWORD` | Annual |
| App Store Connect API key | GitHub Actions secret `ASC_KEY` | Annual |
| Google Play service account JSON | GitHub Actions secret `GOOGLE_PLAY_SERVICE_ACCOUNT` | Annual |
| Sentry DSN (per env) | GitHub Actions environment variables (not secret -- DSNs are public) | N/A |
| Firebase App Distribution SA | GitHub Actions secret `FIREBASE_SERVICE_ACCOUNT` | Annual |
| Slack webhook URL | GitHub Actions secret `SLACK_WEBHOOK` | On compromise |
| Cognito pool IDs, client IDs | `config/{env}.json` (checked in -- not secret) | N/A |
| Third-party API keys (future) | AWS Secrets Manager per environment | 90-day rotation via Lambda |

**Principle:** GitHub Actions secrets hold CI/CD operational secrets (signing keys, store credentials). AWS Secrets Manager holds runtime secrets consumed by Lambda functions. Environment configuration (API URLs, pool IDs) is checked into the repo as it is not sensitive.

### 7.2 Code Signing Setup

**Android:**
1. Generate release keystore: `keytool -genkey -v -keystore release.keystore -alias alpha -keyalg RSA -keysize 2048 -validity 10000`.
2. Base64 encode: `base64 -i release.keystore`.
3. Store in GitHub secret `ANDROID_KEYSTORE`.
4. Composite action `.github/actions/setup-signing` decodes and writes `android/release.keystore` and `android/key.properties` at build time.
5. Enroll in Google Play App Signing (Google holds the upload key; the release key is managed by Google).

**iOS:**
1. Create App Store Connect API key (not personal Apple ID).
2. Initialize Fastlane Match with S3 storage backend: `fastlane match init --storage_mode s3`.
3. Generate certificates and provisioning profiles: `fastlane match appstore`.
4. Certificates stored encrypted in S3 bucket in alpha-staging account.
5. CI fetches via `fastlane match appstore --readonly`.

### 7.3 Dependency Scanning in CI

Added to `ci.yml` as a non-blocking advisory job initially, promoted to blocking after initial remediation:

```yaml
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: OSV Scanner (Flutter/Dart)
        uses: google/osv-scanner-action/osv-scanner-action@v1
        with:
          scan-args: --lockfile=pubspec.lock
      - name: npm audit (Backend)
        run: cd infra && npm audit --audit-level=high
      - name: Semgrep (Backend SAST)
        uses: semgrep/semgrep-action@v1
        with:
          config: p/default
```

Weekly scheduled `dependency-update.yml` runs Renovate or Dependabot to propose dependency updates.

### 7.4 Branch Protection Rules

Applied to `main` and `release/*` branches:

| Rule | Value |
|------|-------|
| Require pull request reviews | 1 approval minimum |
| Dismiss stale reviews on new pushes | Yes |
| Require status checks to pass | `analyze`, `unit-tests`, `backend-checks` |
| Require branches to be up-to-date | Yes |
| Require conversation resolution | Yes |
| Restrict force pushes | No one |
| Restrict deletions | Yes (for `release/*`) |
| Require signed commits | Optional (enable if team uses GPG) |

### 7.5 WAF / Rate Limiting

AWS WAF v2 on CloudFront (prod only initially):

| Rule | Action | Rationale |
|------|--------|-----------|
| AWS Managed Rules - Common Rule Set | Block | OWASP top 10 |
| AWS Managed Rules - Known Bad Inputs | Block | SQL injection, XSS |
| Rate-based rule: 1000 requests/5 min per IP | Block | DDoS / abuse protection |
| Rate-based rule: 100 mutations/5 min per IP | Block | Prevent mutation abuse |
| Geo-restriction | None initially | Enable if needed post-launch |

AppSync has native throttle controls (default 1000 requests/second). Set per-environment:
- Dev/Test: 100 req/s
- Dogfood/Stage: 500 req/s
- Prod: 1000 req/s (increase on demand)

---

## 8. Disaster Recovery & Rollback

### 8.1 Backend Rollback

**CDK / Lambda:**
1. Lambda functions deployed with aliases (`$LATEST` -> `live` alias).
2. CodeDeploy canary: new version receives 10% traffic for 10 minutes. CloudWatch alarm on error rate triggers automatic rollback.
3. Manual rollback: redeploy previous release branch via `deploy-prod.yml` with the previous version number.
4. CDK maintains CloudFormation stack state; rollback reverts all resources to previous template.

**Time to rollback:** Under 10 minutes (CDK deploy of previous commit).

### 8.2 Web Rollback

1. Each prod web deployment is stored under a versioned S3 prefix: `s3://alpha-prod-web/v1.2.0/`.
2. The `latest/` prefix is the active deployment served by CloudFront.
3. Rollback: sync the previous version to `latest/` and invalidate CloudFront.
4. One-command rollback:
   ```bash
   aws s3 sync s3://alpha-prod-web/v<prev>/ s3://alpha-prod-web/latest/ --delete
   aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
   ```
5. **Time to rollback:** Under 5 minutes.

### 8.3 Mobile Rollback

Mobile rollback is inherently limited because users control their update timing.

1. **Feature flags (AppConfig):** Disable broken features server-side within minutes. This is the primary rollback mechanism for mobile.
2. **Halt staged rollout:** In Google Play Console, halt the rollout at current percentage. In App Store Connect, remove the version from sale if critical.
3. **Hotfix process:**
   - Branch `hotfix/<ticket>` from `release/<current-version>`.
   - Fix, merge to release branch, trigger stage deploy.
   - QA verifies on stage.
   - Expedited prod deploy (same pipeline, same approval).
   - Google Play: expedited review (usually 1-2 hours). App Store: request expedited review.
4. **Time to hotfix:** 4-8 hours (includes build, QA, store review).

### 8.4 Database Backup and Restore

| Mechanism | Environment | RPO | RTO | Details |
|-----------|-------------|-----|-----|---------|
| DynamoDB Point-in-Time Recovery | Stage, Prod | 1 second | ~30 min | Continuous backups, restore to any point in last 35 days |
| DynamoDB On-Demand Backup | Prod | At backup time | ~30 min | Triggered before every prod deployment, retained 90 days |
| Table Export to S3 | Prod | Daily | 1-2 hours | Nightly export for analytics and long-term archive |

**Restore procedure:**
1. Create a new table from PITR or on-demand backup.
2. Update CDK stack to point to new table (or rename original, rename restored).
3. Deploy CDK stack.
4. Verify data integrity.

### 8.5 Incident Response Runbook Template

```
## Incident: [TITLE]
### Detection
- Alert fired: [alarm name] at [timestamp]
- Impact: [user-facing description]
- Severity: P[0-3]

### Diagnosis
1. Check CloudWatch dashboard: AlPHA-prod-Overview
2. Check Sentry for new errors/crashes
3. Check recent deployments: `gh run list --workflow=deploy-prod.yml`
4. Check Lambda logs: `aws logs tail /aws/lambda/alpha-prod-<function>`
5. Check DynamoDB throttles: CloudWatch -> DynamoDB -> ThrottledRequests

### Mitigation
- [ ] If deployment-related: rollback backend (redeploy previous version)
- [ ] If web-related: rollback web (S3 sync previous version)
- [ ] If mobile-related: toggle feature flag off via AppConfig
- [ ] If data-related: restore from PITR

### Communication
- Slack #alpha-incidents: post initial assessment within 15 min
- Update every 30 min until resolved

### Post-Mortem
- [ ] Timeline documented
- [ ] Root cause identified
- [ ] Action items created
- [ ] Monitoring gaps addressed
```

---

## 9. Cost Management

### 9.1 Per-Environment Monthly Cost Estimates

| Service | Dev | Test | Dogfood | Stage | Prod (1K DAU) |
|---------|-----|------|---------|-------|---------------|
| DynamoDB | $1-3 | $1 | $3-5 | $2-5 | $3-10 |
| AppSync | $1-3 | $1 | $5-10 | $2-5 | $10-30 |
| Lambda | $0-1 | $0-1 | $1-3 | $1-2 | $1-5 |
| Cognito | Free | Free | Free | Free | Free (<50K MAU) |
| S3 + CloudFront | $1 | $1 | $2 | $2 | $1-5 |
| CloudWatch | $2 | $1 | $3 | $5 | $5-10 |
| Secrets Manager | $0.50 | $0.50 | $0.50 | $0.50 | $0.50 |
| WAF | -- | -- | -- | -- | $5-10 |
| Synthetics | -- | -- | -- | -- | $3-5 |
| **Subtotal** | **$6-10** | **$5-7** | **$15-25** | **$13-20** | **$30-80** |

**GitHub Actions estimated cost:**
- macOS runners: ~$0.08/min. iOS builds ~12 min each. With dogfood (nightly) + PRs (~10/week) + releases: ~$50-100/month.
- Linux runners: included in free tier (2000 min/month) or ~$10-20/month overflow.
- **Total CI/CD: $60-120/month.**

**Total estimated monthly cost (all environments): $130-260/month.**

### 9.2 AWS Budget Alerts

| Budget | Threshold | Action |
|--------|-----------|--------|
| alpha-dev account | $30/month | Email DevOps |
| alpha-staging account | $60/month | Email DevOps |
| alpha-prod account | $100/month | Email DevOps + Tech Lead |
| alpha-prod account | $200/month | Email DevOps + Tech Lead + PagerDuty |

### 9.3 Cost Optimization Checklist

- [ ] Lambda ARM64 (Graviton) for all functions (20% cheaper, better performance).
- [ ] Lambda memory right-sized based on X-Ray/Power Tuning results.
- [ ] Lambda concurrency limits per function to prevent runaway invocations.
- [ ] DynamoDB on-demand to start; evaluate provisioned + auto-scaling when traffic stabilizes.
- [ ] CloudWatch log retention set per environment (7d dev, 90d prod -- not infinite).
- [ ] S3 lifecycle policies: move old web versions to Glacier after 90 days.
- [ ] CloudFront caching maximized (static assets: 1 year, API responses: per-query TTL).
- [ ] Dev/test resources: consider scheduling (stop at night) -- not applicable for serverless but relevant for any future EC2/RDS.
- [ ] Cleanup unused resources quarterly.
- [ ] Review reserved capacity when prod usage patterns are stable (6+ months post-launch).

---

## 10. Collaboration Points

### 10.1 With Software Engineer

| Touchpoint | Details |
|------------|---------|
| **Local dev environment** | DevOps provides Docker Compose for local DynamoDB. Documents how to run `flutter run` against dev backend. Provides `config/dev.json` with dev API endpoints. |
| **Environment variable contract** | DevOps defines the shape of `config/{env}.json`. Software Engineer consumes via `--dart-define-from-file`. Any new env var must be added to all environment configs and documented. |
| **Build configuration** | Software Engineer owns `pubspec.yaml`, `build.gradle`, `Podfile`. DevOps consumes these in CI. Changes that affect build (new native dependencies, Xcode version bumps) must be communicated to DevOps. |
| **CDK stack changes** | Software Engineer adds new Lambda functions or modifies the GraphQL schema. DevOps reviews for infra impact (new IAM permissions, new DynamoDB GSIs, EventBridge rules). |
| **Fastlane lanes** | Software Engineer writes Fastlane lane logic (build commands, metadata). DevOps integrates into CI workflows. |
| **Feature flag management** | DevOps provisions AppConfig. Software Engineer defines and manages flag values. |
| **Debugging production issues** | DevOps provides CloudWatch log access and Sentry project access. Software Engineer diagnoses application-level bugs. |

### 10.2 With QA Engineer

| Touchpoint | Details |
|------------|---------|
| **Test environment provisioning** | DevOps provisions test and stage environments. QA uses them for manual and automated testing. |
| **CI test job requirements** | QA defines test tags, coverage thresholds, and flaky test policies. DevOps implements the CI jobs that execute them. |
| **Test data seeding** | DevOps provides the seeding script infrastructure. QA defines the fixture data content. |
| **Integration test runners** | DevOps configures emulator/simulator jobs in CI. QA writes the integration tests. |
| **Device farm integration** | If Firebase Test Lab or AWS Device Farm is needed, DevOps provisions and integrates. QA defines device matrix and test suites. |
| **QA gate on stage** | DevOps configures GitHub environment protection rule requiring QA approval. QA performs sign-off. |
| **E2E test environment** | DevOps ensures stage environment is stable and seeded before E2E runs. QA owns E2E test authoring and maintenance. |
| **Load testing infrastructure** | DevOps provisions k6/Artillery runners and target environment capacity. QA defines load test scenarios. |

### 10.3 With Product Designer

| Touchpoint | Details |
|------------|---------|
| **Web hosting for design previews** | DevOps can configure preview deployments for PRs (Vercel-style) using S3 + CloudFront with PR-specific prefixes if the team wants visual review of web UI changes. |
| **CDN configuration** | Font files, images, and other static assets served via CloudFront. DevOps configures cache headers and CORS. Designer provides asset files. |
| **Golden test review** | When golden tests fail due to intentional UI changes, Designer may be consulted. DevOps ensures golden diffs are posted as PR comments for visual review. |

---

### Critical Files for Implementation

- `/Users/alastairdrong/wip/AlPHA/docs/app/plan-cicd-release.md` - Primary reference for pipeline structure, environment matrix, branching strategy, and Fastlane configuration that DevOps must implement.
- `/Users/alastairdrong/wip/AlPHA/docs/infra/aws-backend.md` - Defines all CDK stacks, DynamoDB schema, AppSync configuration, Lambda functions, and multi-environment setup that DevOps must provision.
- `/Users/alastairdrong/wip/AlPHA/docs/app/plan-testing-strategy.md` - Specifies which tests run in which CI stage, coverage thresholds, and quality gates that DevOps must enforce in pipeline jobs.
- `/Users/alastairdrong/wip/AlPHA/docs/app/plan-flutter-app.md` - Contains the Flutter project structure, dependencies, and platform-specific build requirements that DevOps must accommodate in CI runners and caching.
- `/Users/alastairdrong/wip/AlPHA/docs/the-alastair-method.md` - Product context necessary to understand data model complexity and inform infrastructure capacity planning decisions.
