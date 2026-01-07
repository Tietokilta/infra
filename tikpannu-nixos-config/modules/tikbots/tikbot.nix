{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.tikbot;
in
{
  sops.secrets.tikbot-envFile = lib.mkIf cfg.enable {
    sopsFile = ../secrets/tikbot.yaml;
    owner = cfg.user;
  };

  services.tikbots.tikbot = {
    enable = true;
    envFile = config.sops.secrets.tikbot-envFile.path;
  };
}
