{
  config,
  ...
}:
{
  sops.secrets = {
    discourse-admin-password = {
      sopsFile = ../../secrets/discourse.yaml;
      owner = config.systemd.services.discourse.serviceConfig.User;
    };

    discourse-mailgun-smtp-password = {
      sopsFile = ../../secrets/discourse.yaml;
      owner = config.systemd.services.discourse.serviceConfig.User;
    };
  };
}
