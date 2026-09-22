{
  config,
  lib,
  ...
}:
let
  cfg = config.services.umami;
in
{
  sops.secrets = lib.mkIf cfg.enable {
    umami-app-secret = {
      sopsFile = ../secrets/umami.yaml;
    };
  };
}
