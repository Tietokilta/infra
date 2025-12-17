{
  config,
  ...
}:
{
  sops.secrets.wappupokemonbot-envFile = {
    sopsFile = ../secrets/wappupokemonbot.yaml;
    owner = config.services.tikbots.wappupokemonbot.user;
  };

  services.tikbots.wappupokemonbot = {
    enable = true;
    envFile = config.sops.secrets.wappupokemonbot-envFile.path;
  };
}
