# Claude Code Agent Runner — Homelab VM Specification

## Purpose

Dedicated VM for running concurrent Claude Code agent sessions for AlPHA development. Handles project scaffolding, code generation, CI-adjacent tasks, and multi-agent coordination.

## Hardware

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| vCPU | 4 | 8 |
| RAM | 16 GB | 32 GB |
| Disk | 50 GB SSD | 100 GB SSD |
| Network | 50 Mbps | 100+ Mbps, low latency |

### Why these numbers

- **CPU:** Claude Code agents are I/O-bound (API round-trips, git, file ops). Extra cores help when running Flutter analyzer, tests, or Docker containers alongside agents.
- **RAM:** Each Claude Code session uses ~200-500 MB. Running 5-6 concurrent agents + Flutter SDK + Docker (local DynamoDB) + Node.js tooling peaks around 20-24 GB.
- **Disk:** Flutter SDK (~2 GB), Android SDK (~5 GB), Docker images (~3 GB), project dependencies, and build artifacts. 100 GB leaves room for growth.
- **Network:** Every agent action is an API call. Latency matters more than throughput.

## Operating System

Ubuntu 24.04 LTS (server, no desktop environment needed).

## Software to Install

### Core

- **Git** 2.40+
- **Docker Engine** + **Docker Compose v2** (for local DynamoDB, future services)
- **Node.js 20 LTS** via `nvm` (backend Lambda development, CDK)
- **npm** (ships with Node.js)
- **Claude Code CLI** (`npm install -g @anthropic-ai/claude-code`)
- **GitHub CLI** (`gh`) — authenticated with a token scoped to `repo`, `read:org`, `admin:public_key`
- **AWS CLI v2** — configured with credentials for account `773469078444`, region `us-west-2`

### Flutter Toolchain

- **Flutter SDK** 3.24.x (stable channel)
- **Dart SDK** (bundled with Flutter)
- **Android SDK** (command-line tools only, no Android Studio needed)
  - Platform SDK: API 34
  - Build tools: 34.0.0
  - Platform tools
  - Accept licenses: `sdkmanager --licenses`
- **Chrome/Chromium** (for `flutter test` on web and `flutter drive`)

### Backend Toolchain

- **TypeScript** 5.x (`npm install -g typescript`)
- **AWS CDK CLI** (`npm install -g aws-cdk`)
- **esbuild** (installed per-project via npm)
- **Jest** (installed per-project via npm)

### Quality / CI Tools

- **Dart formatter** (bundled with Dart SDK)
- **Flutter analyzer** (bundled with Flutter SDK)
- **ESLint** (installed per-project via npm)
- **Prettier** (installed per-project via npm)

## Configuration

### Claude Code

The CLI needs an Anthropic API key. Set via environment variable:

```bash
export ANTHROPIC_API_KEY=<key>
```

To persist across sessions, add to `/etc/environment` or the service user's `~/.bashrc`.

### SSH Key

Generate an SSH key for the VM and add it as a deploy key on the `dev-dull/AL_PHA` repo (with write access), or add it to the `dev-dull` GitHub account:

```bash
ssh-keygen -t ed25519 -C "alpha-agent-runner"
```

### AWS Credentials

```bash
aws configure
# AWS Access Key ID: (from ~/.aws/credentials)
# AWS Secret Access Key: (from ~/.aws/credentials)
# Default region: us-west-2
# Default output: yaml
```

### Docker (DynamoDB Local)

Verify Docker runs without `sudo`:

```bash
sudo usermod -aG docker $USER
```

### Flutter

```bash
flutter doctor  # should show no errors for Android + Web + Linux
flutter config --no-analytics
```

## Not Required

- **macOS / Xcode** — iOS builds will run on GitHub Actions macOS runners, not on this VM.
- **Android emulator** — integration tests that need an emulator will run in CI or on a developer's local machine.
- **Desktop environment / GUI** — headless is fine. Chrome runs headless for web tests.
- **GPU** — not needed.

## Provisioning Script

A bootstrap script will be added to the repo at `scripts/setup-agent-runner.sh` once the VM is stood up. It will install all of the above and validate the environment.
