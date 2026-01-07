{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.wappupokemonbot;
in
{
  sops = lib.mkIf cfg.enable {
    secrets.wappupokemonbot-token = {
      sopsFile = ../secrets/wappupokemonbot.yaml;
      owner = cfg.user;
    };
    templates.wappupokemonbot-env = {
      owner = cfg.user;
      content = ''
        TELEGRAM_BOT_TOKEN=${config.sops.placeholder.wappupokemonbot-token}
      '';
    };
  };

  services.tikbots.wappupokemonbot = {
    enable = true;
    envFile = config.sops.templates.wappupokemonbot-env.path;
  };
}
