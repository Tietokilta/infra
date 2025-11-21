{
  config,
  ...
}:
{
  sops.secrets.tikbot-envFile = {
    sopsFile = ../../secrets/tikbot.yaml;
    owner = config.services.tikbots.tikbot.user;
  };

  services.tikbots.tikbot = {
    enable = true;
    envFile = config.sops.secrets.tikbot-envFile.path;
  };
}
