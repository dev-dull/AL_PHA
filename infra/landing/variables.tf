variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit + Workers:Edit scopes"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (found in dashboard sidebar)"
  type        = string
}

variable "domain" {
  description = "Root domain"
  type        = string
  default     = "planyr.day"
}
