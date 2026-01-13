output "domain" {
  value = mailgun_domain.this.name
}

output "api_url" {
  value = "https://api.eu.mailgun.net"
}

output "api_url_with_domain" {
  value = "https://api.eu.mailgun.net/v3/${mailgun_domain.this.name}"
}

output "smtp_host" {
  value = "smtp.eu.mailgun.org"
}

output "smtp_port" {
  value = 587
}

output "smtp_login" {
  value = var.create_smtp_credential ? "${var.smtp_login}@${mailgun_domain.this.name}" : null
}

output "smtp_password" {
  value     = var.create_smtp_credential ? random_password.smtp[0].result : null
  sensitive = true
}

output "mail_from" {
  value = "noreply@${mailgun_domain.this.name}"
}
