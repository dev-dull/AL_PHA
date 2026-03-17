# AlPHA — Project Coordination & Delivery Plan

**Project:** AlPHA (Alastair Planner & Habit App)
**Platforms:** Android, iOS, Web (Flutter) + AWS Serverless Backend
**Duration:** 12 weeks (6 sprints of 2 weeks)
**Date:** March 15, 2026

---

## 1. Team Structure & RACI

### 1.1 Team Roster

| Role | Abbreviation | Primary Responsibility |
|------|-------------|----------------------|
| Software Engineer (Flutter) | **SE** | Flutter app: UI, state management, local DB, sync client |
| Backend Engineer (AWS) | **BE** | CDK infra, Lambda resolvers, DynamoDB, AppSync, Cognito |
| QA Engineer | **QA** | Test strategy execution, automation, regression, manual QA |
| Product Designer | **PD** | Figma designs, design system tokens, UX flows, usability |
| DevOps Engineer | **DO** | CI/CD pipelines, environments, monitoring, release tooling |

### 1.2 RACI Matrix

| Deliverable | SE | BE | QA | PD | DO |
|-------------|----|----|----|----|-----|
| **Board Grid (Matrix View)** | R | C | C | A | I |
| **Marker Cycling & Interactions** | R | I | C | A | I |
| **Migration Flow (Frontend)** | R | C | C | A | I |
| **Migration Flow (Backend)** | C | R | C | I | I |
| **Offline-First / Sync Engine** | R | A | C | I | I |
| **DynamoDB Single-Table Design** | I | R/A | I | I | I |
| **AppSync GraphQL API** | C | R/A | C | I | I |
| **Cognito Auth Integration** | R | A | C | I | I |
| **Design System (Tokens + Components)** | R | I | I | A | I |
| **Board Templates** | R | C | C | A | I |
| **Onboarding UX** | R | I | C | A | I |
| **CI Pipeline (PR Checks)** | C | C | C | I | R/A |
| **CD Pipeline (Deploy to Prod)** | C | C | I | I | R/A |
| **Dogfood Environment** | I | C | C | I | R/A |
| **Stage/Prod Environments** | I | C | C | I | R/A |
| **Unit Test Suite (Flutter)** | R | I | A | I | I |
| **Unit Test Suite (Backend)** | I | R | A | I | I |
| **Widget & Golden Tests** | R | I | A | C | I |
| **Integration Tests (E2E)** | C | C | R/A | I | C |
| **Load Testing** | I | C | R/A | I | C |
| **Monitoring & Alerting** | I | C | I | I | R/A |
| **App Store Submission (Fastlane)** | C | I | I | I | R/A |
| **Responsive Layout** | R | I | C | A | I |
| **Dark Mode Theming** | R | I | C | A | I |
| **Feature Flags (AppConfig)** | C | R | I | I | A |

**Legend:** R = Responsible, A = Accountable, C = Consulted, I = Informed

---

## 2. Master Sprint Plan (12 Weeks, 6 Sprints)

### Sprint 1 (Week 1-2) — Foundation & Scaffolding

| Role | Deliverables |
|------|-------------|
| **SE** | Flutter project setup (folder structure per plan). Riverpod + GoRouter + Freezed + Isar integration. Define all Freezed data models (Board, Task, Column, Marker). Isar schemas and local data sources. Route definitions with stub screens. ResponsiveScaffold with bottom nav / side rail. |
| **BE** | CDK project scaffolding with pipeline stack. DynamoDB table with GSIs (single-table design). Cognito User Pool with email sign-up. AppSync schema definition (types, enums). Deploy `dev` environment. |
| **QA** | Test strategy finalization. Set up test project structure (`test/unit/`, `test/widget/`, etc.). Create static fixtures (`empty_board.json`, `weekly_board_populated.json`). Write first unit tests for data models. Define test naming conventions. |
| **PD** | Complete Figma design system: color tokens, typography, spacing, marker icons. Board grid wireframes (phone, tablet, web). Board list screen designs. Marker cell interaction specs (tap cycle, long-press picker). |
| **DO** | GitHub repo setup with branch protection on `main`. CI pipeline: `ci.yml` with lint, analyze, unit tests, build verification (Android/iOS/Web). GitHub Actions secrets setup. AWS OIDC federation for CI. `dev` backend auto-deploy workflow. |

**Key Dependencies:**
- SE blocked on PD for design tokens by end of Week 1
- BE and SE must agree on GraphQL schema by end of Week 1
- DO must have CI pipeline running before any PRs merge

**Sprint Goals:** Buildable skeleton app with navigation. Dev backend deployed. CI pipeline green on first PR.

---

### Sprint 2 (Week 3-4) — Core Grid MVP

| Role | Deliverables |
|------|-------------|
| **SE** | BoardListScreen (list, create, delete boards). BoardDetailScreen: full matrix grid with fixed task column + horizontally scrollable marker columns. LinkedScrollControllerGroup for vertical sync. Tap-to-cycle markers (empty -> DOT -> CIRCLE -> X -> empty). Long-press marker picker. Swipe-to-complete / swipe-to-cancel. Drag-to-reorder tasks. Quick-add task via FAB. InteractiveViewer for pinch-to-zoom (mobile). Column management (add, rename, reorder, delete). |
| **BE** | Lambda resolvers: `createBoard`, `getBoard`, `listBoards`, `addTask`, `updateTask`, `completeTask`, `cancelTask`. Column resolvers: `addColumn`, `updateColumn`, `removeColumn`, `reorderColumns`. Marker resolvers: `setMarker`, `removeMarker`, `cycleMarker`. `reorderTasks` resolver. Integration tests for all resolvers. |
| **QA** | Unit tests for marker cycling logic, task state transitions, board CRUD. Widget tests: grid rendering (5 cols x 10 tasks = 50 cells), empty state, scroll behavior. Backend unit tests for Lambda resolvers (mocked DynamoDB). Set up golden test infrastructure (`golden_toolkit` or `alchemist`). |
| **PD** | Task detail sheet designs. Migration flow wireframes (4-step wizard). Template picker screen designs. Refine grid interaction feedback (ripple, scale animation on marker tap). Review and iterate on grid implementation with SE. |
| **DO** | Backend CI: CDK synth validation, backend unit tests in PR pipeline. `test` environment auto-deploy on merge to `main`. Path filtering (frontend vs backend jobs). Coverage reporting to Codecov. |

**Key Dependencies:**
- SE needs BE resolvers functional by mid-Sprint 2 for API integration planning
- QA widget tests depend on SE completing grid widget
- PD migration wireframes needed by Sprint 3 start

**Sprint Goals:** A user can create a weekly board, add tasks, mark them across days, complete them, and reorder them — all persisted locally in Isar. Backend API functional in dev.

---

### Sprint 3 (Week 5-6) — Templates, Migration & Dogfood Setup

| Role | Deliverables |
|------|-------------|
| **SE** | Board templates (Weekly, Monthly, GTD Contexts, Daily Hourly, Project Tracker). Template picker screen. Task detail sheet (edit title, description, priority, deadline). Migration Wizard: end-of-period detection banner, target board selection, task checklist, confirm/cancel. Board archiving. |
| **BE** | `migrateTasks` mutation with DynamoDB transactional logic. Board template data (`TEMPLATE` partition key). `shiftContext` atomic mutation. `dogfood` environment deployed (separate Cognito pool, persistent data). Feature flag item in DynamoDB. |
| **QA** | Widget tests: migration flow dialogs, template picker. Integration tests: board lifecycle, marker workflow, migration cross-board integrity. Golden test baselines for: board grid (empty, populated, dense), marker cell states, migration dialog. Contract tests: validate frontend DTOs match backend GraphQL schema. |
| **PD** | Onboarding carousel designs (3-4 pages with interactive mini-grid demo). Settings screen designs. Dark mode color token variants. Column editor UX. Design review of implemented grid with SE (pixel-level feedback). |
| **DO** | Dogfood pipeline: Fastlane setup, code signing (Android keystore, iOS Match). Firebase App Distribution for Android. TestFlight internal testing for iOS. Web deploy to `dogfood.alpha-app.com`. Nightly build schedule (`deploy-dogfood.yml`). Sentry integration (dev DSN). |

**Key Dependencies:**
- SE migration UI depends on PD wireframes (delivered Sprint 2)
- SE migration UI depends on BE `migrateTasks` resolver
- DO dogfood pipeline must be ready before team begins daily use
- QA contract tests depend on stable GraphQL schema from BE

**Sprint Goals:** Templates and migration flow complete. Dogfood builds distributable to team. Team begins using AlPHA daily starting Week 7.

---

### Sprint 4 (Week 7-8) — Polish, Platform Optimization & Sync Foundation

| Role | Deliverables |
|------|-------------|
| **SE** | Onboarding carousel. Dark mode toggle (ThemeMode.system/light/dark). Keyboard shortcuts (web): N for new task, Cmd+Z undo, arrow keys, Space to cycle. Right-click context menus (web/desktop). Hover states (web). Haptic feedback (mobile). Empty states and loading skeletons. Undo support (snackbar). Collapsed view toggle. Performance profiling (60fps target on 50+ task boards). |
| **BE** | AppSync subscriptions for real-time board updates. Offline conflict resolution Lambda (field-level merge for tasks, last-write-wins for markers). `syncBoard` delta query. EventBridge rule: migration reminder. Recurring task creation via EventBridge scheduled rule. |
| **QA** | Platform-specific UI tests: horizontal scroll sticky column, pinch-to-zoom, responsive breakpoints (phone/tablet/web). Integration tests on real devices: Android emulator (API 30+), iOS Simulator (iPhone 15 Pro), Chrome via `flutter drive`. Performance profiling validation (grid render < 500ms, scroll at 60fps, marker tap < 100ms). Dogfood bug triage (bugs surfaced from daily use). |
| **PD** | Review and refine onboarding flow based on initial dogfood feedback. Accessibility audit: contrast ratios, touch targets (min 44x44), screen reader labels. App icon and splash screen designs. App store screenshot compositions. |
| **DO** | Release pipeline: `deploy-stage.yml`, `deploy-prod.yml`. Sentry source maps + debug symbols upload in CI. CloudWatch dashboards: API latency, error rates, DynamoDB throttles, Lambda durations. CloudWatch alarms: 5xx > 1%, p99 > 2s, throttling. Stage environment CDK stack. |

**Key Dependencies:**
- SE sync client depends on BE subscriptions and `syncBoard` query being functional
- QA device testing depends on DO dogfood builds being stable
- PD app store assets needed before Sprint 6 production launch

**Sprint Goals:** App polished across all three platforms. Real-time sync infrastructure ready. Stage environment deployed. Team has been dogfooding for 1+ week with feedback incorporated.

---

### Sprint 5 (Week 9-10) — Sync Integration, Auth & Pre-Release QA

| Role | Deliverables |
|------|-------------|
| **SE** | AWS Cognito auth: sign up, sign in, sign out, token refresh. Remote data sources (API client with Dio or AppSync client). Sync engine: write-ahead queue in Isar, background processing, delta pull on launch/reconnect, conflict resolution (last-write-wins at field level). Sync status indicator in UI. Connectivity awareness via `connectivity_plus`. Multi-device testing. |
| **BE** | `staging` environment fully deployed. Load testing against staging (k6/Artillery): 100 concurrent users marker toggles, 50 simultaneous board creates, 30 users migrating 20 tasks, 500 concurrent read-heavy users. Tune AppSync response caching per query. DynamoDB capacity monitoring. Security review: resolver authorization checks. |
| **QA** | E2E tests against staging: New User Onboarding journey, Full Week Workflow, Cross-Device Sync (verify within 5s), Context Shifting, Offline Sync. API endpoint testing: all CRUD with valid/invalid payloads, auth checks (401/403). Load test validation (p95 < 200ms writes, < 100ms reads). Regression suite run across all three platforms. Test data isolation: unique test users with cleanup Lambda. |
| **PD** | Final visual QA pass across all platforms (pixel comparison against Figma). App store listing copy: title, subtitle, description, keywords. "What's New" release notes draft. Marketing screenshots finalized. |
| **DO** | Feature flags via AWS AppConfig. Staged rollout configuration for Google Play (5% -> 20% -> 50% -> 100%). `deploy-prod.yml` with manual approval gate. Dependency scanning: `osv-scanner`, `semgrep`, Renovate/Dependabot. SBOM generation. Golden tests in CI with platform-independent rendering. Coverage gates enforced (80% Flutter, 85% backend minimum). |

**Key Dependencies:**
- SE auth/sync depends on BE staging environment being stable
- QA E2E tests depend on SE sync engine + BE staging
- DO prod pipeline must be validated before Sprint 6
- PD app store assets depend on final UI being frozen

**Sprint Goals:** Full auth + sync working end-to-end. Stage environment passes QA. All E2E journeys green. Load tests within SLA. Release candidate ready.

---

### Sprint 6 (Week 11-12) — Release Hardening & Production Launch

| Role | Deliverables |
|------|-------------|
| **SE** | Bug fixes from Stage QA. Performance optimizations based on load test results. Final accessibility pass (screen reader, large-tap-target mode). Error handling polish (network errors, auth token expiry, sync failures). Version bump in `pubspec.yaml`. |
| **BE** | `prod` environment deployed. Runbook documentation for on-call. Auto-rollback configuration: CloudWatch alarm on 5xx > 5% triggers Lambda CodeDeploy rollback. Production DynamoDB backup schedule. Cost guardrails: AWS Budgets at $50/$100/$200. |
| **QA** | Stage QA sign-off checklist execution (all platforms). Smoke tests against production (read-only). Regression on release branch. Verify rollback procedure works. Final coverage report. Sign-off document for production launch. |
| **PD** | App Store/Google Play submission review (screenshots, descriptions, category). Post-launch UX feedback collection plan. v1.1 feature prioritization based on dogfood learnings. |
| **DO** | Production deployment execution: CDK deploy, web S3/CloudFront, Fastlane to App Store + Google Play. CloudFront cache invalidation. Synthetic monitoring via CloudWatch Synthetics. Post-deploy smoke verification. Play Store staged rollout monitoring (5% initial). Release tag (`v1.0.0`) and GitHub Release with changelog. |

**Key Dependencies:**
- All roles depend on QA Stage sign-off before production deploy
- DO prod deploy depends on BE prod environment + SE final build
- App Store review timeline (1-3 days) must be factored into launch date

**Sprint Goals:** Production launch. App live on Google Play, App Store, and web. Monitoring and alerting active. Staged rollout progressing.

---

## 3. Dependency Map

### 3.1 Deliverable Dependency Graph

```
PD: Design Tokens ─────────────► SE: Design System Components
PD: Grid Wireframes ────────────► SE: Board Grid Widget
PD: Migration Wireframes ───────► SE: Migration Wizard UI

BE: GraphQL Schema ─────────────► SE: Remote Data Sources / DTOs
BE: DynamoDB Table + Resolvers ──► BE: AppSync API functional
BE: Cognito User Pool ──────────► SE: Auth Integration
BE: AppSync Subscriptions ──────► SE: Sync Engine
BE: syncBoard Query ────────────► SE: Delta Sync on Reconnect
BE: migrateTasks Mutation ──────► SE: Migration Flow (server-side)
BE: Staging Environment ────────► QA: E2E Tests / Load Tests

SE: Grid Widget Complete ───────► QA: Widget Tests for Grid
SE: Sync Engine Complete ───────► QA: Cross-Device E2E Tests
SE: Auth Complete ──────────────► QA: Full User Journey E2E

DO: CI Pipeline ────────────────► All: PR merging begins
DO: Dogfood Pipeline ───────────► Team: Daily dogfooding starts
DO: Stage Pipeline ─────────────► QA: Stage QA + Sign-off
DO: Prod Pipeline ──────────────► DO: Production deploy

QA: Stage Sign-off ─────────────► DO: Production Deploy (gate)
```

### 3.2 Critical Path

The critical path runs through:

**PD Design Tokens (W1)** -> **SE Grid Widget (W3-4)** -> **SE Migration Flow (W5-6)** -> **BE Sync Infrastructure (W7-8)** -> **SE Sync Engine (W9-10)** -> **QA E2E on Staging (W9-10)** -> **QA Stage Sign-off (W11)** -> **Production Launch (W12)**

Any delay on the grid widget, sync engine, or staging E2E tests directly delays the launch.

### 3.3 Top 5 Cross-Role Dependencies That Could Delay the Project

| # | Dependency | Blocking Role | Blocked Role(s) | Risk Window | Mitigation |
|---|-----------|---------------|-----------------|-------------|------------|
| 1 | **GraphQL schema agreement** | BE | SE, QA | Week 1 | Joint schema design session Day 1-2. Schema locked by end of Week 1. SE can mock API responses until resolvers are ready. |
| 2 | **AppSync subscriptions + syncBoard query** | BE | SE | Week 7-8 | SE builds sync engine against a local mock first. BE delivers subscription infrastructure by mid-Sprint 4. If delayed, SE ships v1.0 as offline-only with sync in v1.1. |
| 3 | **Dogfood pipeline readiness** | DO | All | Week 5-6 | DO starts Fastlane and signing setup in Sprint 2 (parallel work). Fallback: distribute debug APKs manually via Slack while pipeline is finalized. |
| 4 | **Design tokens and grid wireframes** | PD | SE | Week 1-2 | PD delivers tokens by end of Week 1 (hard deadline). SE can use placeholder colors/typography for first 2 days if needed. |
| 5 | **Staging environment stability** | BE + DO | QA | Week 9-10 | BE deploys staging CDK stack by end of Sprint 4. DO validates deploy pipeline against staging in Sprint 4. QA has 2 full weeks (Sprint 5) for E2E testing. Buffer: Sprint 6 Week 1 can absorb overflow QA. |

---

## 4. Communication Plan

### 4.1 Meeting Cadence

| Meeting | Frequency | Duration | Attendees | Purpose |
|---------|-----------|----------|-----------|---------|
| **Daily Standup** | Daily, 9:15 AM | 15 min | All 5 roles | Blockers, progress, today's plan. Async update posted in Slack for anyone who cannot attend. |
| **Sprint Planning** | Biweekly (sprint start) | 90 min | All 5 roles | Review sprint goals, assign stories, identify dependencies, capacity check. |
| **Sprint Review / Demo** | Biweekly (sprint end) | 60 min | All 5 roles + stakeholders | Demo working software. PD shows designs. QA shows test results. Celebrate wins. |
| **Sprint Retrospective** | Biweekly (after review) | 45 min | All 5 roles | What went well, what to improve, action items. Rotate facilitator. |
| **Architecture Sync** | Weekly (Wed) | 30 min | SE, BE, DO | Technical decisions: API contracts, data model changes, infra changes. PD/QA invited as needed. |
| **Design Review** | Weekly (Tue) | 30 min | SE, PD, QA | PD presents designs. SE provides feasibility feedback. QA identifies testability concerns. |
| **QA Sync** | Weekly (Thu) | 20 min | QA, SE, BE | Test results, bug triage, coverage trends, flaky test review. |
| **Release Readiness** | Sprints 5-6 only, twice weekly | 30 min | All 5 roles | Go/no-go checklist, blocker review, launch coordination. |

### 4.2 Async Communication

| Channel | Tool | Purpose |
|---------|------|---------|
| `#alpha-general` | Slack | General project discussion, announcements |
| `#alpha-engineering` | Slack | Technical discussion, PR reviews, architecture questions |
| `#alpha-design` | Slack | Design feedback, Figma links, UX questions |
| `#alpha-bugs` | Slack | Bug reports from dogfooding, linked to Linear issues |
| `#alpha-ci-cd` | Slack | CI/CD notifications (build failures, deploy completions) |
| `#alpha-releases` | Slack | Release announcements, rollout status, incident comms |

### 4.3 Decision-Making Process

1. **Day-to-day technical decisions:** Made by the responsible engineer. Document in PR description or ADR (Architecture Decision Record) if significant.
2. **Cross-role decisions** (API contracts, UX changes affecting backend, test strategy changes): Discussed at Architecture Sync or Design Review. Decision documented in a brief ADR in `/docs/decisions/`.
3. **Scope changes:** Raised at Sprint Planning. Requires agreement from all affected roles. If mid-sprint, escalate to the project lead (Alastair).
4. **Disagreements:** The accountable person (per RACI) has final say. If unresolved, escalate to Alastair within 24 hours.

### 4.4 Escalation Path

```
Individual contributor
    -> Role lead (self, in a 5-person team)
        -> Project Lead (Alastair)
            -> External stakeholders (if applicable)
```

Escalation trigger: any blocker unresolved for more than 24 hours.

---

## 5. Definition of Done

### 5.1 Definition of Done: Feature

A feature is "done" when ALL of the following are true:

- [ ] Code implements the acceptance criteria from the story
- [ ] Code follows project conventions (feature-first structure, Riverpod patterns, Freezed models)
- [ ] Unit tests written and passing (coverage does not drop below minimum threshold)
- [ ] Widget tests written for any new UI components
- [ ] `flutter analyze` reports zero errors and zero warnings
- [ ] `dart format` passes with no changes
- [ ] PR reviewed and approved by at least one other engineer
- [ ] No unresolved PR comments
- [ ] Backend: Lambda resolver unit tests passing with mocked DynamoDB
- [ ] Backend: CDK synth succeeds
- [ ] Visually matches Figma designs (verified by PD or screenshot comparison)
- [ ] Accessible: touch targets >= 44x44, contrast ratios meet WCAG AA
- [ ] Works on all three platforms (Android, iOS, Web) — verified in CI builds
- [ ] No known regressions introduced

### 5.2 Definition of Done: Sprint

- [ ] All committed stories meet the Feature DoD above
- [ ] Sprint goal achieved (as stated in Sprint Planning)
- [ ] All CI checks green on `main`
- [ ] No P0/P1 bugs open from this sprint's work
- [ ] Sprint demo completed with stakeholder acknowledgment
- [ ] Retrospective action items from previous sprint addressed
- [ ] Test coverage at or above minimum thresholds (80% Flutter, 85% backend)
- [ ] Updated goldens committed (if UI changed)

### 5.3 Definition of Done: MVP (Internal, End of Sprint 3)

- [ ] A user can create a board from a template
- [ ] The full matrix grid renders with fixed task column and scrollable marker columns
- [ ] Tap-to-cycle markers works (empty -> DOT -> CIRCLE -> X -> empty)
- [ ] Tasks can be added, reordered, completed (swipe), and cancelled
- [ ] Migration wizard moves incomplete tasks to a new board
- [ ] All data persists locally in Isar across app restarts
- [ ] App runs on Android, iOS, and Web without crashes
- [ ] Dogfood builds are distributable to the team

### 5.4 Definition of Done: v1.0 Production Release

- [ ] All MVP criteria met
- [ ] Auth: users can sign up, sign in, sign out, and refresh tokens via Cognito
- [ ] Sync: data syncs across devices within 5 seconds (real-time subscriptions)
- [ ] Offline: changes made offline sync on reconnect without data loss
- [ ] Onboarding: new users see a 3-4 page carousel explaining the method
- [ ] Dark mode: full light/dark theme support
- [ ] Web: keyboard shortcuts, hover states, right-click menus
- [ ] Mobile: haptic feedback, pinch-to-zoom
- [ ] Performance: grid renders in < 500ms, scrolls at 60fps, marker tap < 100ms
- [ ] All E2E journeys pass on staging (5 critical user journeys)
- [ ] Load tests pass: p95 < 200ms writes, < 100ms reads at 100 concurrent users
- [ ] Zero P0 bugs, zero P1 bugs
- [ ] Stage QA sign-off document completed
- [ ] App store listings complete (screenshots, descriptions, metadata)
- [ ] Monitoring and alerting active in production
- [ ] Rollback procedure tested and documented
- [ ] Crash-free rate > 99% over 48-hour bake period

---

## 6. Risk Register

| # | Risk | Likelihood | Impact | Owner | Mitigation | Contingency |
|---|------|-----------|--------|-------|------------|-------------|
| 1 | **Grid performance degrades on large boards** (31 cols x 100+ tasks) | Medium | High | SE | Profile early in Sprint 2 with synthetic data. Use `ListView.builder` for virtualized rows. Granular Riverpod providers per cell to avoid full-grid rebuilds. | Limit board size (max 50 tasks per board). Implement pagination or lazy loading for rows. |
| 2 | **Isar web support instability** | Medium | High | SE | Test web persistence in Sprint 1. Abstract behind repository interface. | Fall back to Drift + sqlite3 WASM. Repository interface makes swap possible without UI changes. |
| 3 | **Sync conflicts cause data loss** | Low | Critical | BE + SE | Field-level last-write-wins with `_version` and `_lastModified`. Markers are idempotent. Conflict resolution Lambda with custom merge logic. | Add conflict UI: show user both versions and let them choose. Log all conflicts for analysis. |
| 4 | **Dogfood pipeline delays** (signing, provisioning profiles, App Store Connect issues) | High | Medium | DO | Start Fastlane + signing setup in Sprint 2 (2 sprints before needed). Test with manual builds first. | Distribute unsigned debug builds via Slack/email. Web dogfood as primary channel (no signing needed). |
| 5 | **GraphQL schema changes mid-project** break frontend/backend contract | Medium | Medium | BE + SE | Lock schema by end of Sprint 1. Use contract tests in CI. Any schema change requires an ADR and migration plan. | Versioned schema with backward compatibility. Frontend handles unknown fields gracefully. |
| 6 | **App Store review rejection** delays production launch | Medium | High | DO + PD | Follow Apple/Google guidelines from Sprint 1. Include privacy policy, data deletion endpoint. Submit early for review in Sprint 5 (TestFlight external). | Have web launch as fallback. Fix rejection issues and resubmit within 24 hours. |
| 7 | **Scroll synchronization bugs** between frozen task column and marker grid | Medium | Medium | SE | Use `linked_scroll_controller` package (proven solution). Write widget tests for scroll sync in Sprint 2. | Fall back to a single unified scroll view without frozen column (degraded UX but functional). |
| 8 | **Scope creep** — team adds features beyond MVP during early sprints | High | Medium | All | MVP scope explicitly defined and narrow (no sync, no templates in Phase 1). Sprint planning enforces scope discipline. Any new requests go to backlog. | Cut features from later sprints (onboarding, dark mode, keyboard shortcuts are all deferrable to v1.1). |
| 9 | **Single point of failure** — each role has exactly one person | High | High | All | Cross-train: SE and BE do weekly pairing sessions. Document all decisions in ADRs. Runbooks for CI/CD and deployment. | Alastair acts as backup for any role. Defer non-critical work if someone is unavailable. Prioritize critical path items. |
| 10 | **AWS service limits or unexpected costs** | Low | Medium | BE + DO | Set AWS Budgets alerts at $50/$100/$200. Use on-demand DynamoDB (no capacity planning needed). Lambda concurrency limits per function. | Switch to provisioned DynamoDB with auto-scaling. Optimize Lambda memory/timeout. Review and eliminate unused resources. |

---

## 7. Milestone Timeline

| Week | Milestone | Description | Exit Criteria |
|------|-----------|-------------|---------------|
| **W1** | **Project Kickoff** | Sprint 1 begins. All roles start foundation work. | Repo created, CI pipeline running, branch protection enabled, Sprint 1 planned. |
| **W2** | **Design System Approved** | PD delivers design tokens, SE integrates. | Color tokens, typography, marker icons, grid cell sizing approved by PD and implemented in code. Dark mode variants defined. |
| **W2** | **First Buildable App (Skeleton)** | Navigation works, all screens are stubs, local DB connected. | `flutter run` succeeds on all 3 platforms. GoRouter routes resolve. Isar reads/writes work. CI builds green. |
| **W4** | **Core Grid Functional (MVP Internally)** | The defining feature works end-to-end locally. | A user can create a weekly board, add 10+ tasks, tap-to-cycle markers, swipe-to-complete, drag-to-reorder. All persisted in Isar. |
| **W6** | **Dogfood Launch** | Team installs AlPHA and begins daily use. | Dogfood builds distributed via Firebase App Distribution (Android) and TestFlight (iOS). Web at `dogfood.alpha-app.com`. Templates and migration functional. At least 3 team members using it as their real planner. |
| **W8** | **Sync Infrastructure Ready** | Backend subscriptions, conflict resolution, and delta sync operational. | AppSync subscriptions deliver marker changes across devices. `syncBoard` query returns deltas. Conflict resolution Lambda tested. Stage environment deployed. |
| **W10** | **Feature Complete** | All v1.0 features implemented and integrated. | Auth + sync working end-to-end. All 5 E2E journeys pass on staging. Load tests within SLA. No P0/P1 bugs. |
| **W11** | **Stage QA Sign-off** | QA completes full regression on staging across all platforms. | QA sign-off document completed. Zero P0, zero P1 bugs. Coverage thresholds met. Performance benchmarks met. Rollback procedure verified. |
| **W12** | **Production Launch** | App live for end users. | App published on Google Play and App Store. Web live at `app.alpha-app.com`. Production monitoring active. Staged rollout at 5%. Crash-free rate > 99% after 48-hour bake. |

---

## 8. Quality Gates

### 8.1 Gate: Merging a PR

All of the following must pass:

- [ ] `flutter analyze --fatal-infos` — zero errors
- [ ] `dart format --set-exit-if-changed .` — no formatting violations
- [ ] All unit tests pass (`flutter test --coverage`)
- [ ] All widget tests pass
- [ ] Golden tests pass (or diff explicitly approved with updated baselines)
- [ ] Backend unit tests pass (if backend code changed)
- [ ] CDK synth succeeds (if infra code changed)
- [ ] Contract tests pass (if API models changed)
- [ ] Build verification succeeds on all affected platforms (path-filtered)
- [ ] Code coverage does not drop below minimum threshold
- [ ] At least one approval from a peer reviewer
- [ ] No unresolved PR conversations
- [ ] Conventional commit message format (`feat:`, `fix:`, `chore:`, etc.)

### 8.2 Gate: Deploying to Dogfood

- [ ] All PR gate criteria met on `main`
- [ ] Integration tests pass on CI (emulator + simulator + Chrome)
- [ ] No P0 bugs open
- [ ] Release-signed builds succeed (Android APK, iOS IPA)
- [ ] Sentry DSN configured for dogfood environment

### 8.3 Gate: Deploying to Stage

- [ ] Release branch (`release/<version>`) cut from `main`
- [ ] Version bumped in `pubspec.yaml`
- [ ] Changelog generated
- [ ] All dogfood gate criteria met
- [ ] Full signed release builds succeed (Android AAB, iOS IPA, Web bundle)
- [ ] Backend CDK deploy to staging succeeds
- [ ] Smoke tests pass against staging backend

### 8.4 Gate: Releasing to Production

- [ ] QA sign-off document completed and signed
- [ ] All 5 E2E critical user journeys pass on staging
- [ ] Load test results within SLA (p95 < 200ms writes, < 100ms reads)
- [ ] Zero P0 bugs, zero P1 bugs
- [ ] Security scan: no high/critical vulnerabilities (`osv-scanner`, `semgrep`)
- [ ] Code coverage at or above targets (80% Flutter, 85% backend)
- [ ] Rollback procedure tested on staging
- [ ] App store listing complete (screenshots, descriptions, privacy policy)
- [ ] Monitoring dashboards and alarms configured for production
- [ ] Deploy window: business hours, not Friday
- [ ] Manual approval from project lead (Alastair)
- [ ] Post-deploy: smoke tests pass against production (read-only)
- [ ] Post-deploy: crash-free rate > 99% over 48-hour bake period before expanding rollout

---

## 9. Tooling & Process

### 9.1 Project Management

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Linear** | Issue tracking, sprint boards, backlog | Workspace: `AlPHA`. Project prefix: `ALP`. Sprint cycles: 2 weeks. Labels: `frontend`, `backend`, `devops`, `design`, `qa`. Priorities: Urgent, High, Medium, Low. States: Backlog, Todo, In Progress, In Review, Done. |

**Linear Conventions:**
- Every PR references a Linear issue (`ALP-42`)
- Issues have acceptance criteria before entering a sprint
- Bugs from dogfood are filed with `bug` label and `dogfood` tag
- Epics map to major deliverables (Board Grid, Migration, Sync Engine, CI/CD, etc.)

### 9.2 Documentation

| Tool | Purpose |
|------|---------|
| **Notion** | Product specs, meeting notes, sprint retrospectives, runbooks, ADRs, onboarding guide |
| **`/docs/` in repo** | Technical architecture plans (the 5 documents already created), API contracts, ADRs co-located with code |
| **`/docs/decisions/`** | Architecture Decision Records (ADR-001-graphql-over-rest.md, etc.) |
| **Inline code comments** | Complex logic explanation only (not obvious code) |
| **README.md** | Project setup, local development guide, environment configuration |

### 9.3 Design

| Tool | Purpose |
|------|---------|
| **Figma** | All UI/UX design. Organized by: Design System (tokens, components), Screens (per feature), Prototypes (interactive flows). |
| **Figma Dev Mode** | SE references designs with exact spacing, colors, and assets. PD marks screens as "Ready for Dev." |

### 9.4 Code & Version Control

| Tool | Purpose |
|------|---------|
| **GitHub** | Source code, PRs, branch protection, Actions CI/CD |
| **Conventional Commits** | Enforced commit message format for changelog generation |
| **`git-cliff`** | Auto-generate CHANGELOG.md from conventional commits |
| **Squash merge** | All PRs squash-merged to `main` for clean history |

### 9.5 Communication

| Tool | Purpose |
|------|---------|
| **Slack** | Primary async communication. Channels listed in section 4.2. |
| **Slack Integrations** | GitHub notifications in `#alpha-ci-cd`. Linear notifications in `#alpha-engineering`. Sentry alerts in `#alpha-releases`. |
| **Google Meet / Zoom** | Synchronous meetings (standups, planning, reviews, retros) |

### 9.6 Monitoring & Incident Management

| Tool | Purpose |
|------|---------|
| **Sentry** | Crash reporting, performance monitoring, release tracking (Flutter + backend) |
| **AWS CloudWatch** | Infrastructure metrics, dashboards, alarms, logs |
| **CloudWatch Synthetics** | Synthetic browser checks for web health |
| **PagerDuty or Opsgenie** (post-launch) | On-call rotation, incident escalation |

**Incident Severity:**
| Level | Definition | Response Time | Example |
|-------|-----------|---------------|---------|
| P0 | Service down, data loss | 15 min | Sync causes data deletion |
| P1 | Major feature broken, workaround exists | 1 hour | Migration fails for all users |
| P2 | Minor feature broken | Next business day | Dark mode colors incorrect |
| P3 | Cosmetic or minor UX issue | Next sprint | Alignment off by 2px |

### 9.7 Process Summary

| Process | Tool | Cadence |
|---------|------|---------|
| Sprint planning | Linear + Google Meet | Biweekly |
| Code review | GitHub PRs | Every PR (< 24hr turnaround target) |
| Design handoff | Figma Dev Mode | Continuous |
| Bug tracking | Linear (label: `bug`) | Continuous |
| Dependency updates | Renovate/Dependabot | Weekly automated PRs |
| Security scanning | `osv-scanner` + `semgrep` | Every CI run |
| Release notes | `git-cliff` + manual "What's New" | Each release |
| Retrospective action tracking | Notion | Biweekly review |
