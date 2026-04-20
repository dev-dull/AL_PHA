resource "cloudflare_zone_settings_override" "planyr" {
  zone_id = data.cloudflare_zone.planyr.id

  settings {
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    ssl                      = "strict"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    brotli                   = "on"
    http3                    = "on"
    security_level           = "medium"
  }
}
