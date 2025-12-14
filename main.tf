terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.35"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~>3.4"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~>2.32"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
  backend "azurerm" {
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    resource_group_name  = "terraform-state"
    storage_account_name = "tikprodterraform"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "3aa1704b-82a5-478f-bc57-2cf4f0876a5e"
}

provider "azuread" {
}

provider "dns" {
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

locals {
  resource_group_location = "northeurope"
}

module "keyvault" {
  source                  = "./modules/keyvault"
  env_name                = "prod"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
  keyvault_secrets = [
    "digitransit-subscription-key",
    "ilmo-auth-jwt-secret",
    "ilmo-edit-token-secret",
    "ilmo-mailgun-api-key",
    "ilmo-mailgun-domain",
    "invoice-mailgun-api-key",
    "tikjob-ghost-mail-username",
    "tikjob-ghost-mail-password",
    "tenttiarkisto-django-secret-key",
    "github-app-key",
    "google-oauth-client-id",
    "google-oauth-client-secret",
    "muistinnollaus-smtp-email",
    "muistinnollaus-smtp-password",
    "muistinnollaus-strapi-token",
    "muistinnollaus-paytrail-merchant-id",
    "muistinnollaus-paytrail-secret-key",
    "mongodb-atlas-public-key",
    "mongodb-atlas-private-key",
    "github-challenge-value",
    "mailgun-sender",
    "mailgun-receiver",
    "mailgun-api-key",
    "mailgun-domain",
    "mailgun-url",
    "tikjob-tg-bot-token",
    "tikjob-tg-ghost-hook-secret",
    "vaultwarden-api-key",
    "vaultwarden-smtp-username",
    "vaultwarden-smtp-password",
    "status-telegram-token",
    "status-telegram-channel-id",
    "registry-mailgun-api-key",
    "registry-stripe-api-key",
    "registry-stripe-webhook-secret"
  ]
}

module "dns_prod" {
  source                  = "./modules/dns/root"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
  zone_name               = "tietokilta.fi"
}

module "dns_staging" {
  source                  = "./modules/dns/root"
  env_name                = "staging"
  resource_group_location = local.resource_group_location
  zone_name               = "tietokila.fi"
}
module "dns_m0" {
  source                  = "./modules/dns/root"
  env_name                = "m0"
  resource_group_location = local.resource_group_location
  zone_name               = "muistinnollaus.fi"
}
module "dns_juvusivu" {
  source                  = "./modules/dns/root"
  env_name                = "juvu"
  resource_group_location = local.resource_group_location
  zone_name               = "juhlavuosi.fi"
}
module "tenttiarkisto_dns_zone" {
  source                  = "./modules/dns/root"
  env_name                = "prod"
  resource_group_location = module.common.resource_group_location
  # legacy due to previous setup
  resource_group_name = module.common.resource_group_name
  zone_name           = "tenttiarkisto.fi"
}
module "dns_github" {
  source = "./modules/dns/github"

  resource_group_name = module.dns_prod.resource_group_name
  zone_name           = module.dns_prod.root_zone_name
  challenge_name      = "_github-challenge-Tietokilta-org"
  challenge_value     = module.keyvault.secrets["github-challenge-value"]

}
module "mailman" {
  source = "./modules/dns/mailman"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "list"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJN6WyS7YQcOKO4MKsSbrYfjL8hh24ot/0uQysHte3eqscbbwCFVlgmsg3423by3e20ZSBMhRXdtIkYdgn8wkfPyZlHVEOvOJBCR+tKqtexxQEbkk8LqmEzVggNZoLLX06wYNqt2Nxl++dlvUuB4IxmPPGQed3Xr7HBT8OZmKJYQIDAQAB"
}

module "mailing_staging" {
  source = "./modules/dns/mailing"

  dns_resource_group_name = module.dns_staging.resource_group_name
  root_zone_name          = module.dns_staging.root_zone_name
  subdomain               = "list"

  dkim_selector = "mg"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZGR9aFa3+4SaHMkvO44EzQzbmMPEYqryH1tsgBlNErA5Qd/UNtCgQ+vy1uO2SyOGZDoD6xEDVZ8Mqh4JXXX3GVvEgpESjSlj+RkhCLY9JGVJwkgVWTUD65qkLJ9NpADBMQUhzJgxIv+It3zxbFDUOmLv2+Qee7d/MR1Gfgn/wNwIDAQAB"
}

module "dns_misc_prod" {
  source                  = "./modules/dns/prod"
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name

  dmarc_report_domains = [
    module.mailman.fqdn,
    module.mailing_staging.fqdn,
    module.tikjob_app.fqdn,
    module.ilmo.fqdn,
    module.invoicing.fqdn,
    module.forum.fqdn,
    module.mattermost.fqdn,
    module.registry.fqdn,
  ]
}

module "common" {
  source                  = "./modules/common"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
}
resource "azurerm_key_vault_secret" "postgres_admin_user" {
  name         = "postgres-admin-user"
  value        = module.common.postgres_admin_username
  key_vault_id = module.keyvault.keyvault_id
}
resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = module.common.postgres_admin_password
  key_vault_id = module.keyvault.keyvault_id
}

module "mongodb" {
  source                    = "./modules/mongodb"
  mongodb_atlas_public_key  = module.keyvault.secrets["mongodb-atlas-public-key"]
  mongodb_atlas_private_key = module.keyvault.secrets["mongodb-atlas-private-key"]
  serverless_instance_name  = "tikweb-serverless-instance"
  project_name              = "tikweb-${terraform.workspace}"
  atlas_region              = "EUROPE_WEST"
}

resource "azurerm_key_vault_secret" "mongo_db_connection_string" {
  name         = "mongo-db-connection-string"
  value        = module.mongodb.db_connection_string
  key_vault_id = module.keyvault.keyvault_id
}

module "web" {
  source                       = "./modules/web"
  resource_group_location      = local.resource_group_location
  resource_group_name          = module.common.resource_group_name
  app_service_plan_id          = module.common.tikweb_app_plan_id
  acme_account_key             = module.common.acme_account_key
  root_zone_name               = module.dns_prod.root_zone_name
  dns_resource_group_name      = module.dns_prod.resource_group_name
  subdomain                    = "@"
  environment                  = "prod"
  mongo_connection_string      = "${module.mongodb.db_connection_string}/payload?retryWrites=true&w=majority"
  google_oauth_client_id       = module.keyvault.secrets["google-oauth-client-id"]
  google_oauth_client_secret   = module.keyvault.secrets["google-oauth-client-secret"]
  public_ilmo_url              = "https://${module.ilmo.fqdn}"
  public_laskugeneraattori_url = "https://${module.invoicing.fqdn}"
  public_legacy_url            = "https://${module.oldweb.fqdn}"
  digitransit_subscription_key = module.keyvault.secrets["digitransit-subscription-key"]
  mailgun_sender               = module.keyvault.secrets["mailgun-sender"]
  mailgun_receiver             = module.keyvault.secrets["mailgun-receiver"]
  mailgun_api_key              = module.keyvault.secrets["mailgun-api-key"]
  mailgun_domain               = module.keyvault.secrets["mailgun-domain"]
  mailgun_url                  = module.keyvault.secrets["mailgun-url"]
}

resource "azurerm_key_vault_secret" "cms_password" {
  name         = "cms-password"
  value        = module.web.payload_password
  key_vault_id = module.keyvault.keyvault_id
}
module "ilmo" {
  source                  = "./modules/ilmo"
  environment             = "prod"
  tikweb_rg_name          = module.common.resource_group_name
  tikweb_rg_location      = module.common.resource_group_location
  tikweb_app_plan_id      = module.common.tikweb_app_plan_id
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_username = module.common.postgres_admin_username
  postgres_admin_password = module.common.postgres_admin_password
  postgres_server_id      = module.common.postgres_server_id
  edit_token_secret       = module.keyvault.secrets["ilmo-edit-token-secret"]
  auth_jwt_secret         = module.keyvault.secrets["ilmo-auth-jwt-secret"]
  mailgun_api_key         = module.keyvault.secrets["ilmo-mailgun-api-key"]
  mailgun_domain          = module.keyvault.secrets["ilmo-mailgun-domain"]
  website_url             = "https://tietokilta.fi"
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "ilmo"
  acme_account_key        = module.common.acme_account_key

  dkim_selector = "mg"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDQYrVWefo+vOByb07hseOTt1Ryu47Yt5odumYka5JiEt1p/FHl/ZeeY8gehxV0Dv4PIWM91htY2JY2UZguGYFODzqq9Y9AeKjWpq1dyFKiM8nlrI6GRin0kY7SRLeSgpcVFuwNLiT74Wqy477Geq+l5/Stwho23kHu/pXiQuVUMwIDAQAB"
}

module "ilmo_staging" {
  source                  = "./modules/ilmo_staging"
  environment             = "staging"
  tikweb_rg_name          = module.common.resource_group_name
  tikweb_rg_location      = module.common.resource_group_location
  tikweb_app_plan_id      = module.common.tikweb_app_plan_id
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_username = module.common.postgres_admin_username
  postgres_admin_password = module.common.postgres_admin_password
  postgres_server_id      = module.common.postgres_server_id
  edit_token_secret       = module.keyvault.secrets["ilmo-edit-token-secret"]
  auth_jwt_secret         = module.keyvault.secrets["ilmo-auth-jwt-secret"]
  mailgun_api_key         = module.keyvault.secrets["ilmo-mailgun-api-key"]
  mailgun_domain          = module.keyvault.secrets["ilmo-mailgun-domain"]
  website_url             = "https://tietokilta.fi"
}

module "histotik" {
  source                  = "./modules/histotik"
  env_name                = "prod"
  resource_group_location = local.resource_group_location

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "histotik"
}

module "tenttiarkisto" {
  source                       = "./modules/tenttiarkisto"
  env_name                     = "prod"
  postgres_resource_group_name = module.common.resource_group_name
  resource_group_location      = local.resource_group_location
  postgres_server_fqdn         = module.common.postgres_server_fqdn
  postgres_admin_password      = module.common.postgres_admin_password
  postgres_server_id           = module.common.postgres_server_id
  tikweb_app_plan_id           = module.common.tikweb_app_plan_id
  tikweb_app_plan_rg_location  = module.common.resource_group_location
  tikweb_app_plan_rg_name      = module.common.resource_group_name
  django_secret_key            = module.keyvault.secrets["tenttiarkisto-django-secret-key"]
  acme_account_key             = module.common.acme_account_key
  dns_resource_group_name      = module.tenttiarkisto_dns_zone.resource_group_name
  root_zone_name               = module.tenttiarkisto_dns_zone.root_zone_name
}

module "voo" {
  source                  = "./modules/voo"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
}

module "tikjob_storage" {
  source                  = "./modules/recruiting/storage"
  env_name                = "prod"
  resource_group_location = local.resource_group_location
  ghost_db_username       = "tikrekryadmin"
}

module "tikjob_app" {
  source = "./modules/recruiting/ghost"

  environment        = "prod"
  tikweb_app_plan_id = module.common.tikweb_app_plan_id
  tikweb_rg_name     = module.common.resource_group_name
  tikweb_rg_location = module.common.resource_group_location

  mysql_db_name  = module.tikjob_storage.mysql_db_name
  mysql_fqdn     = module.tikjob_storage.mysql_fqdn
  mysql_username = module.tikjob_storage.mysql_username
  mysql_password = module.tikjob_storage.mysql_password

  storage_account_name = module.tikjob_storage.storage_account_name
  storage_account_key  = module.tikjob_storage.storage_account_key
  storage_share_name   = module.tikjob_storage.storage_share_name

  ghost_mail_host     = "smtp.eu.mailgun.org"
  ghost_mail_port     = 465
  ghost_mail_username = module.keyvault.secrets["tikjob-ghost-mail-username"]
  ghost_mail_password = module.keyvault.secrets["tikjob-ghost-mail-password"]

  acme_account_key = module.common.acme_account_key

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "rekry"
  dkim_selector           = "mta"
  dkim_key                = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIvN+P4vQeU88WdDcISgVgZzXnGXeCZHU7h826JhE8p3UvLO4NuHJKuXuKmVcRXFcxOro4MJg2dIaU/Yei8QAVN7ZIxXXbPDLncDKJ4XEjdRajbY1oTPJAuy/KjInozSEeZeVwA2aYtbQ/Ttq4fXGwgKe2rS2uvDBVseqj4Oa6wwIDAQAB"
}

module "tikjob_tg_bot" {
  source = "./modules/recruiting/tg-bot"

  env_name                   = "prod"
  tikweb_rg_name             = module.common.resource_group_name
  tikweb_rg_location         = local.resource_group_location
  tikweb_app_plan_id         = module.common.tikweb_app_plan_id
  storage_account_name       = module.tikjob_storage.storage_account_name
  storage_account_access_key = module.tikjob_storage.storage_account_key
  bot_token                  = module.keyvault.secrets["tikjob-tg-bot-token"]
  ghost_hook_secret          = module.keyvault.secrets["tikjob-tg-ghost-hook-secret"]
  channel_id                 = "-1001347398697"
}

module "forum" {
  source   = "./modules/forum"
  env_name = "prod"

  resource_group_location = local.resource_group_location

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "vaalit"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCzppfPnLHshnORT2P0C3OBuo80OCsCOpLHQS2txfRq2k+y+P4rocFy4z1H0397Ijy6wKM+VI3qOnc8RzVkaZib8+p08jBf/O/hxTwTkuMrotdIo2zrfBq+T1AaYMj4zNJnPt10+vLptpEA6m0XIWsu7wTRE6WfqHjlHj7CwkhTzwIDAQAB"
}

module "mattermost" {
  source = "./modules/mattermost"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "mm"

  dkim_selector = "email"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEIS79WkHcT6Dr1KLQp9CkLtzCqU/We4SqYWSQSQkfabOdWyoKkQJlwjLzbMjLSQtX35gPvSQXIzqYnC0dhppQoNleu25Me0QIfjwc7cWSvYUC1HEp1OX5+NTZXHvCuc0KdhEEQ3tUTUnSAk7QZZMUlX+gSQV5MFMEO9Wcqk4E1wIDAQAB"

  mattermost_ip = module.forum.forum_ip
}

module "discourse" {
  source = "./modules/discourse"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "vaalit.staging"
  discourse_ip            = "46.62.222.17"
}

module "tikpannu" {
  source = "./modules/tikpannu"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "pannu"
  tikpannu_ip             = "46.62.222.17"
}

module "invoicing" {
  source = "./modules/invoicing"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "laskutus"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsAjLp5HRzTjMcjGGjZ75U42hCUaopuficYZiyLL3Ail/BmTqh2K8LRxN2UrWXOzVGLEh2F9PR6MC7nqR1Vj+3yR4+5nznwfmZh0cnX4Q2asm7A76st4uVwkVk0y21Mj1wufBIz885XCk+rzeorMOCU+lDZUIehYk1sVSDcubDuBAwJ9TBLXj2EMmcrD1KmJWMca0d5I6RfB+ZD7hG97rWhpgPuKYP7gaT6/t+ekXIJn9ZJmNRoIm/5X04AdM20ywwUrVe6NzWkB8eFuVy01DZki2bI9JnPwjnjw+KgZWrZBhtaYE8umVExmwGmI9PTzrHrknaBKQ0UBrDqSlyXuWgwIDAQAB"

  mailgun_url             = "https://api.eu.mailgun.net/v3/laskutus.tietokilta.fi/messages"
  mailgun_user            = "api"
  mailgun_api_key         = module.keyvault.secrets["invoice-mailgun-api-key"]
  resource_group_location = local.resource_group_location
  resource_group_name     = module.common.resource_group_name
  app_service_plan_id     = module.common.tikweb_app_plan_id
  acme_account_key        = module.common.acme_account_key
}

module "registry" {
  source                  = "./modules/registry"
  resource_group_location = local.resource_group_location
  resource_group_name     = module.common.resource_group_name
  app_service_plan_id     = module.common.tikweb_app_plan_id
  postgres_server_id      = module.common.postgres_server_id
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_username = module.common.postgres_admin_username
  postgres_admin_password = module.common.postgres_admin_password
  environment             = "prod"
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "rekisteri"
  acme_account_key        = module.common.acme_account_key
  mailgun_url             = "https://api.eu.mailgun.net"
  mailgun_domain          = "rekisteri.tietokilta.fi"
  mailgun_api_key         = module.keyvault.secrets["registry-mailgun-api-key"]
  stripe_api_key          = module.keyvault.secrets["registry-stripe-api-key"]
  stripe_webhook_secret   = module.keyvault.secrets["registry-stripe-webhook-secret"]
  dkim_selector           = "email"
  dkim_key                = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDpz7YQQUpscjJYLhaXr+jcyN30EwI90CmjRmsvuN1XrsZjTJgXTxATi0WlV80FrWuTBsV2WTv8dK7F7S0xnkh515IxTBrDMau6jUp90nWNp5Oy9DkqW8fNPJUiFWiazWilOPXuARjlOgk18e8d/CvTpke0R1G/S12KXkTshO06JQIDAQAB"
}

module "oldweb" {
  source                  = "./modules/oldweb"
  environment             = "prod"
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_username = module.common.postgres_admin_username
  postgres_admin_password = module.common.postgres_admin_password
  postgres_server_id      = module.common.postgres_server_id
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "old"
  acme_account_key        = module.common.acme_account_key
  tikweb_app_plan_id      = module.common.tikweb_app_plan_id
  tikweb_rg_location      = module.common.resource_group_location
  tikweb_rg_name          = module.common.resource_group_name
  location                = local.resource_group_location
}

module "vaultwarden" {
  environment                          = "prod"
  source                               = "./modules/vaultwarden"
  admin_api_key                        = module.keyvault.secrets["vaultwarden-api-key"]
  app_service_plan_id                  = module.common.tikweb_app_plan_id
  app_service_plan_location            = local.resource_group_location
  app_service_plan_resource_group_name = module.common.resource_group_name
  db_password                          = module.common.postgres_admin_password
  db_username                          = module.common.postgres_admin_username
  db_name                              = "vaultwarden"
  db_host                              = module.common.postgres_server_fqdn
  location                             = local.resource_group_location
  smtp_host                            = "smtp.eu.mailgun.org"
  vaultwarden_smtp_from                = "vault@tietokilta.fi"
  vaultwarden_smtp_username            = module.keyvault.secrets["vaultwarden-smtp-username"]
  vaultwarden_smtp_password            = module.keyvault.secrets["vaultwarden-smtp-password"]
  dns_resource_group_name              = module.dns_prod.resource_group_name
  acme_account_key                     = module.common.acme_account_key
  root_zone_name                       = module.dns_prod.root_zone_name
  subdomain                            = "vault"
  dkim_selector                        = "s1"
  dkim_key                             = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI4os0RXkOmE7+FJGIYDdUFmzGlmmXPzyvvyuCRUzeOBCBiHQQKTqDULecVmbtuROXA2cVBqjZyxHPVcvLLtPOTJYEUTrZ7xpkLDJmtPUIn5iPqXDMbv7QG/XbXN1njRCC9GUPcNvHTocNXe8ZwTK92Ax/l586bLyIzfBUR+yfQQIDAQAB"
}

module "github-ci-roles" {
  source = "./modules/github-ci"
  repo_app_service_map = {
    "Tietokilta/web" : [module.web.web_app_id]
    "Tietokilta/laskugeneraattori" : [module.invoicing.invoicing_app_id]
    "Tietokilta/ilmomasiina" : [module.ilmo.app_id]
    "Tietokilta/ISOpistekortti" : [module.isopistekortti.app_id]
    "Tietokilta/m0-ilmotunkki" : [module.m0.frontend_app_id, module.m0.strapi_app_id]
    "Tietokilta/juvusivu" : [module.juvusivu.juvusivu_app_id]
    "Tietokilta/infra" : [module.status.app_id]
    "Tietokilta/rekisteri" : [module.registry.registry_app_id]
  }
}
# Output Azure Client IDs for Each Repository
output "github_actions_azure_client_ids" {
  description = "Mapping of GitHub repositories to their AZURE_CLIENT_ID"
  value       = module.github-ci-roles.azure_client_ids
}

# Output Azure Subscription ID
output "github_actions_azure_subscription_id" {
  description = "AZURE_SUBSCIPTION_ID in Github Actions"
  value       = module.github-ci-roles.azure_subscription_id
}

# Output Azure Tenant ID
output "github_actions_azure_tenant_id" {
  description = "AZURE_TENANT_ID in Github Actions"
  value       = module.github-ci-roles.azure_tenant_id
}

module "m0" {
  source                              = "./modules/m0"
  resource_group_location             = local.resource_group_location
  acme_account_key                    = module.common.acme_account_key
  app_service_plan_id                 = module.common.tikweb_app_plan_id
  web_resource_group_name             = module.common.resource_group_name
  mail_dns_resource_group_name        = module.dns_prod.resource_group_name
  m0_dns_zone_name                    = module.dns_m0.root_zone_name
  m0_dns_resource_group_name          = module.dns_m0.resource_group_name
  postgres_server_fqdn                = module.common.postgres_server_fqdn
  postgres_admin_password             = module.common.postgres_admin_password
  postgres_server_id                  = module.common.postgres_server_id
  dkim_key                            = "k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7Ho1FBsK9IyD0dl7gA/fh8vA1abuLrgB/e//bIrcFb8NS/Ze3W2cMUHZ7T3UvjnjlPhutWMblBX39oFBj9jp+lFpy+AwKSYBz7GZ/WCdZTsN01U6miUGiMEdfB/pOmIXKJKtkT9wHk7RJkRl9MTnUY60UgVweZFfdJbAnMXNKvulEZAEsKlE+8M5qDJDvnGNs99/wDl9nam5KyGPFLTzxeBSlsEQo6qa5qPcmn3vxbgVlwrFDt9KmbFcgAbq3wZ+W0MwwL54wPZVmHCwObi4sIptokmZVlmaXyvTwJ8eklrwJD51TLlpinwNBUpvgFGWDC62nLLt3wOHFSadtuxWCwIDAQAB"
  dkim_selector                       = "email"
  mail_subdomain                      = "m0"
  smtp_email                          = module.keyvault.secrets["muistinnollaus-smtp-email"]
  smtp_password                       = module.keyvault.secrets["muistinnollaus-smtp-password"]
  mail_dns_zone_name                  = module.dns_prod.root_zone_name
  strapi_token                        = module.keyvault.secrets["muistinnollaus-strapi-token"]
  muistinnollaus_paytrail_merchant_id = module.keyvault.secrets["muistinnollaus-paytrail-merchant-id"]
  muistinnollaus_paytrail_secret_key  = module.keyvault.secrets["muistinnollaus-paytrail-secret-key"]
}

module "juvusivu" {
  source                               = "./modules/juvusivu"
  environment                          = "prod"
  app_service_plan_id                  = module.common.tikweb_app_plan_id
  app_service_plan_location            = local.resource_group_location
  app_service_plan_resource_group_name = module.common.resource_group_name
  location                             = local.resource_group_location
  postgres_server_fqdn                 = module.common.postgres_server_fqdn
  postgres_admin_username              = module.common.postgres_admin_username
  postgres_admin_password              = module.common.postgres_admin_password
  postgres_server_id                   = module.common.postgres_server_id
  acme_account_key                     = module.common.acme_account_key
  dns_resource_group_name              = module.dns_juvusivu.resource_group_name
  root_zone_name                       = module.dns_juvusivu.root_zone_name
  m0_dns_resource_group_name           = module.dns_m0.resource_group_name
  m0_dns_zone_name                     = module.dns_m0.root_zone_name
}

module "status" {
  source                               = "./modules/status"
  app_service_plan_id                  = module.common.tikweb_app_plan_id
  app_service_plan_location            = local.resource_group_location
  app_service_plan_resource_group_name = module.common.resource_group_name
  location                             = local.resource_group_location
  dns_resource_group_name              = module.dns_prod.resource_group_name
  acme_account_key                     = module.common.acme_account_key
  root_zone_name                       = module.dns_prod.root_zone_name
  telegram_token                       = module.keyvault.secrets["status-telegram-token"]
  telegram_channel_id                  = module.keyvault.secrets["status-telegram-channel-id"]
  subdomain                            = "status"
}

module "isopistekortti" {
  source                  = "./modules/isopistekortti"
  resource_group_location = local.resource_group_location
  resource_group_name     = module.common.resource_group_name
  app_service_plan_id     = module.common.tikweb_app_plan_id
  postgres_server_id      = module.common.postgres_server_id
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_username = module.common.postgres_admin_username
  postgres_admin_password = module.common.postgres_admin_password
  subdomain               = "iso"
  environment             = "prod"
  root_zone_name          = module.dns_prod.root_zone_name
  dns_resource_group_name = module.dns_prod.resource_group_name
  acme_account_key        = module.common.acme_account_key
}
