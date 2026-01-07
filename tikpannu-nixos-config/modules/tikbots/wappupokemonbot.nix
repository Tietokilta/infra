{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.wappupokemonbot;
in
{
  sops.secrets.wappupokemonbot-envFile = lib.mkIf cfg.enable {
    sopsFile = ../secrets/wappupokemonbot.yaml;
    owner = cfg.user;
  };

  services.tikbots.wappupokemonbot = {
    enable = true;
    envFile = config.sops.secrets.wappupokemonbot-envFile.path;
  };
}
