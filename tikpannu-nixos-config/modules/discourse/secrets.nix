{
  config,
  lib,
  ...
}:
let
  cfg = config.services.discourse;
in
{
  sops.secrets = lib.mkIf cfg.enable {
    discourse-admin-password = {
      sopsFile = ../secrets/discourse.yaml;
      owner = config.systemd.services.discourse.serviceConfig.User;
    };

    discourse-mailgun-smtp-password = {
      sopsFile = ../secrets/discourse.yaml;
      owner = config.systemd.services.discourse.serviceConfig.User;
    };
  };
}
