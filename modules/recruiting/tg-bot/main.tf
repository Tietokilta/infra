resource "azurerm_linux_function_app" "tg-bot" {
  name                = "tik-rekry-tg-bot-${var.env_name}"
  resource_group_name = var.tikweb_rg_name
  location            = var.tikweb_rg_location

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  service_plan_id = var.tikweb_app_plan_id

  site_config {
    application_stack {
      docker {
        registry_url = "https://ghcr.io"
        image_name   = "tietokilta/rekry-tg-hook"
        image_tag    = "latest"
      }
    }
  }

  app_settings = {
    BOT_TOKEN         = var.bot_token
    GHOST_HOOK_SECRET = var.ghost_hook_secret
    CHANNEL_ID        = var.channel_id
  }

  lifecycle {
    ignore_changes = [
      site_config.0.application_stack, # deployments are made outside of Terraform
    ]
  }
}
