terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.87.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.19.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
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
  source   = "./modules/keyvault"
  env_name = "prod"

  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
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
  mongo_connection_string      = module.mongodb.db_connection_string
  google_oauth_client_id       = module.keyvault.secrets["google-oauth-client-id"]
  google_oauth_client_secret   = module.keyvault.secrets["google-oauth-client-secret"]
  public_ilmo_url              = "https://${module.ilmo.fqdn}"
  public_legacy_url            = "https://tietokilta.fi"
  digitransit_subscription_key = module.keyvault.secrets["digitransit-subscription-key"]
}
resource "azurerm_key_vault_secret" "cms_password" {
  name         = "cms-password"
  value        = module.web.payload_password
  key_vault_id = module.keyvault.keyvault_id
}
module "ilmo" {
  source                  = "./modules/ilmo"
  env_name                = "prod"
  resource_group_name     = module.common.resource_group_name
  resource_group_location = local.resource_group_location
  postgres_server_fqdn    = module.common.postgres_server_fqdn
  postgres_admin_password = module.common.postgres_admin_password
  postgres_server_id      = module.common.postgres_server_id
  edit_token_secret       = module.keyvault.secrets["ilmo-edit-token-secret"]
  auth_jwt_secret         = module.keyvault.secrets["ilmo-auth-jwt-secret"]
  mailgun_api_key         = module.keyvault.secrets["ilmo-mailgun-api-key"]
  mailgun_domain          = module.keyvault.secrets["ilmo-mailgun-domain"]
  website_events_url      = "https://tietokilta.fi"
  tikweb_app_plan_id      = module.common.tikweb_app_plan_id
  tikweb_rg_location      = module.common.resource_group_location
  tikweb_rg_name          = module.common.resource_group_name
  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "ilmo"
  acme_account_key        = module.common.acme_account_key

  dkim_selector = "mg"
  dkim_key      = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDQYrVWefo+vOByb07hseOTt1Ryu47Yt5odumYka5JiEt1p/FHl/ZeeY8gehxV0Dv4PIWM91htY2JY2UZguGYFODzqq9Y9AeKjWpq1dyFKiM8nlrI6GRin0kY7SRLeSgpcVFuwNLiT74Wqy477Geq+l5/Stwho23kHu/pXiQuVUMwIDAQAB"
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

  env_name                = "prod"
  resource_group_name     = module.tikjob_storage.resource_group_name
  resource_group_location = module.tikjob_storage.resource_group_location
  tikweb_app_plan_id      = module.common.tikweb_app_plan_id
  tikweb_rg_name          = module.common.resource_group_name
  tikweb_rg_location      = module.common.resource_group_location
  ghost_front_url         = "https://rekry.tietokilta.fi"

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

module "invoicing" {
  source   = "./modules/invoicing"
  env_name = "prod"

  dns_resource_group_name = module.dns_prod.resource_group_name
  root_zone_name          = module.dns_prod.root_zone_name
  subdomain               = "laskutus"

  dkim_selector = "mta"
  dkim_key      = "k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsAjLp5HRzTjMcjGGjZ75U42hCUaopuficYZiyLL3Ail/BmTqh2K8LRxN2UrWXOzVGLEh2F9PR6MC7nqR1Vj+3yR4+5nznwfmZh0cnX4Q2asm7A76st4uVwkVk0y21Mj1wufBIz885XCk+rzeorMOCU+lDZUIehYk1sVSDcubDuBAwJ9TBLXj2EMmcrD1KmJWMca0d5I6RfB+ZD7hG97rWhpgPuKYP7gaT6/t+ekXIJn9ZJmNRoIm/5X04AdM20ywwUrVe6NzWkB8eFuVy01DZki2bI9JnPwjnjw+KgZWrZBhtaYE8umVExmwGmI9PTzrHrknaBKQ0UBrDqSlyXuWgwIDAQAB"
}

# module "m0" {
#   source                              = "./modules/m0"
#   resource_group_location             = local.resource_group_location
#   acme_account_key                    = module.common.acme_account_key
#   app_service_plan_id                 = module.common.tikweb_app_plan_id
#   web_resource_group_name             = module.common.resource_group_name
#   mail_dns_resource_group_name        = module.dns_prod.resource_group_name
#   postgres_server_fqdn                = module.common.postgres_server_fqdn
#   postgres_admin_password             = module.common.postgres_admin_password
#   postgres_server_id                  = module.common.postgres_server_id
#   dkim_key                            = "k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7Ho1FBsK9IyD0dl7gA/fh8vA1abuLrgB/e//bIrcFb8NS/Ze3W2cMUHZ7T3UvjnjlPhutWMblBX39oFBj9jp+lFpy+AwKSYBz7GZ/WCdZTsN01U6miUGiMEdfB/pOmIXKJKtkT9wHk7RJkRl9MTnUY60UgVweZFfdJbAnMXNKvulEZAEsKlE+8M5qDJDvnGNs99/wDl9nam5KyGPFLTzxeBSlsEQo6qa5qPcmn3vxbgVlwrFDt9KmbFcgAbq3wZ+W0MwwL54wPZVmHCwObi4sIptokmZVlmaXyvTwJ8eklrwJD51TLlpinwNBUpvgFGWDC62nLLt3wOHFSadtuxWCwIDAQAB"
#   dkim_selector                       = "email"
#   mail_subdomain                      = "m0"
#   smtp_email                          = module.keyvault.m0_smtp_email
#   smtp_password                       = module.keyvault.m0_smtp_password
#   mail_dns_zone_name                  = module.dns_prod.root_zone_name
#   strapi_token                        = module.keyvault.muistinnollaus_strapi_token
#   muistinnollaus_paytrail_merchant_id = module.keyvault.muistinnollaus_paytrail_merchant_id
#   muistinnollaus_paytrail_secret_key  = module.keyvault.muistinnollaus_paytrail_secret_key
# }
