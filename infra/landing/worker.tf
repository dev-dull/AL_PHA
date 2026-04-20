resource "cloudflare_worker_script" "landing" {
  account_id = var.cloudflare_account_id
  name       = "planyr-landing"
  content = replace(
    file("${path.module}/worker.js"),
    "__OG_IMAGE_B64__",
    filebase64("${path.module}/og-image.png"),
  )
  module = true
}

resource "cloudflare_worker_domain" "apex" {
  account_id = var.cloudflare_account_id
  hostname   = var.domain
  service    = cloudflare_worker_script.landing.name
  zone_id    = data.cloudflare_zone.planyr.id
}

resource "cloudflare_worker_domain" "www" {
  account_id = var.cloudflare_account_id
  hostname   = "www.${var.domain}"
  service    = cloudflare_worker_script.landing.name
  zone_id    = data.cloudflare_zone.planyr.id
}
