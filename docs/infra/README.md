# Infrastructure

This directory covers everything running outside the Flutter app itself:
cloud backend, marketing/landing site, and developer tooling infra.

## What's where

| Piece                  | Provider       | Location in repo       | Doc                                |
|------------------------|----------------|------------------------|------------------------------------|
| App backend (sync, auth)| AWS (us-west-2) | `infra/`               | [aws-backend.md](./aws-backend.md) |
| Landing page (planyr.day)| Cloudflare     | `infra/landing/`       | [landing.md](./landing.md)         |
| Agent runner VM        | Homelab        | `infra/` (spec only)   | [agent-vm.md](./agent-vm.md)       |

## Naming note

The app is currently named **AlPHA** in code, repo, and AWS resources (state
bucket `alpha-terraform-state-773469078444`, Cognito pool, etc.) but will be
renamed to **planyr** to match the domain `planyr.day`. The rename is
planned but not yet executed — when you see `alpha-*` in infra, that's why.
Docs will start using "planyr" once the code rename lands.

## Terraform state backends

Both `infra/` and `infra/landing/` share an S3 backend:

- Bucket: `alpha-terraform-state-773469078444` (us-west-2)
- DynamoDB lock table: `alpha-terraform-locks`
- Keys:
  - `alpha/terraform.tfstate` — main app backend
  - `planyr-landing/terraform.tfstate` — landing page

Bootstrap is handled by `infra/bootstrap.sh`; teardown by `infra/teardown.sh`.

## Secrets

- **AWS app backend** — credentials managed via the user's default AWS profile
  (account `773469078444`, region `us-west-2`). No secrets committed.
- **Cloudflare landing** — API token stored in 1Password (`planyr.day` vault,
  `Cloudflare` item). Terraform reads via `op run --env-file=.op.env`. See
  [landing.md](./landing.md) for the full pattern.

Do not commit `terraform.tfvars`, raw tokens, or other secrets. The
`.op.env` files (1Password references only, not secrets) are committed.
