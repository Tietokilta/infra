{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.varjoisopistekortti;
in
{
  sops = lib.mkIf cfg.enable {
    secrets = {
      varjoisopistekortti-token = {
        sopsFile = ../secrets/varjoisopistekortti.yaml;
        owner = cfg.user;
      };
      varjoisopistekortti-admin-ids = {
        sopsFile = ../secrets/varjoisopistekortti.yaml;
        owner = cfg.user;
      };
    };
    templates.varjoisopistekortti-env = {
      owner = cfg.user;
      content = ''
        BOT_TOKEN=${config.sops.placeholder.varjoisopistekortti-token}
        ADMIN_TELEGRAM_IDS=${config.sops.placeholder.varjoisopistekortti-admin-ids}
      '';
    };
  };

  services.tikbots.varjoisopistekortti = {
    enable = true;
    envFile = config.sops.templates.varjoisopistekortti-env.path;
  };
}
