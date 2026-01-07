{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.tikbot;
in
{
  sops = lib.mkIf cfg.enable {
    secrets.tikbot-token = {
      sopsFile = ../secrets/tikbot.yaml;
      owner = cfg.user;
    };
    templates.tikbot-env = {
      owner = cfg.user;
      content = ''
        TELEGRAM_TOKEN=${config.sops.placeholder.tikbot-token}
      '';
    };
  };

  services.tikbots.tikbot = {
    enable = true;
    envFile = config.sops.templates.tikbot-env.path;
  };
}
