# Landing page — planyr.day

A static "coming soon" landing page served from a Cloudflare Worker on
`planyr.day` and `www.planyr.day`.

## Architecture

```
Cloudflare Worker (planyr-landing)
  │
  ├── bound to planyr.day      (via Workers Custom Domain)
  └── bound to www.planyr.day  (via Workers Custom Domain)

  Inline HTML response served with security headers
    (HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy)
```

No S3, no CloudFront, no ACM cert management — Cloudflare handles SSL,
CDN, and DDoS protection automatically. The worker returns the HTML
inline; there is no separate build or deploy pipeline.

## Files

```
infra/landing/
├── main.tf           # Cloudflare provider, S3 state backend
├── variables.tf      # API token, account ID, domain
├── worker.tf         # cloudflare_worker_script + 2 custom domain bindings
├── worker.js         # The HTML + Response, styled to match the app
├── outputs.tf        # Nameservers, URLs, worker name
├── .op.env           # 1Password refs for Terraform env vars (committed)
└── .gitignore        # Ignores tfvars, state, lockfile
```

The worker serves HTML styled to match the app's bullet-journal theme
(Patrick Hand font, cream paper, dot-grid background, ink markers).

## 1Password integration

Secrets live in the **planyr.day** 1Password vault, item **Cloudflare**:

| Field        | Contents               | Sensitive? |
|--------------|------------------------|------------|
| `credential` | Cloudflare API token   | yes        |
| `account_id` | Cloudflare account ID  | no         |

`infra/landing/.op.env` maps these to Terraform-recognized env vars:

```
TF_VAR_cloudflare_api_token=op://planyr.day/Cloudflare/credential
TF_VAR_cloudflare_account_id=op://planyr.day/Cloudflare/account_id
```

`.op.env` contains only references (no actual secrets) and is committed.

## Deploy flow

From a fresh clone:

```sh
# Sign into 1Password CLI (biometric prompt on macOS with desktop app)
op signin

cd infra/landing
terraform init
op run --env-file=.op.env -- terraform plan
op run --env-file=.op.env -- terraform apply
```

To change the landing page content: edit `worker.js`, re-apply. Cache
TTL is 300s so updates show quickly.

## API token scopes

The token stored in 1Password grants:

- Zone:Edit
- DNS:Edit
- Workers Routes:Edit
- Workers Scripts:Edit

**Not granted:** Zone Settings:Edit. That means `cloudflare_zone_settings_override`
cannot be used to force e.g. `always_use_https = "on"` or raise the
minimum TLS version. For `.day` domains this is low-impact because the TLD
is on the HSTS preload list — all major browsers enforce HTTPS regardless.
Add the scope to the token and restore a `zone.tf` resource if tighter
enforcement is needed for non-browser clients.

## Costs

| Item        | Cost          |
|-------------|---------------|
| Domain      | ~$12/yr (at-cost via Cloudflare Registrar) |
| Hosting     | $0 (Workers free tier: 100k req/day) |
| SSL         | $0 (Universal SSL, auto-renewing) |
| DNS         | $0 |

## Tearing down

```sh
cd infra/landing
op run --env-file=.op.env -- terraform destroy
```

This removes the worker and the custom-domain bindings. It does **not**
remove the domain registration or the zone — those were created manually
in the Cloudflare dashboard. To release the domain entirely, cancel it
in the dashboard.
