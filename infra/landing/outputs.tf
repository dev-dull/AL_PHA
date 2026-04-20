output "nameservers" {
  description = "Cloudflare nameservers for this zone"
  value       = data.cloudflare_zone.planyr.name_servers
}

output "zone_id" {
  description = "Cloudflare zone ID"
  value       = data.cloudflare_zone.planyr.id
}

output "worker_name" {
  description = "Worker script serving the landing page"
  value       = cloudflare_worker_script.landing.name
}

output "urls" {
  description = "Live URLs once deployed"
  value = [
    "https://${var.domain}",
    "https://www.${var.domain}",
  ]
}
