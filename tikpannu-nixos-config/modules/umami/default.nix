{
  config,
  lib,
  ...
}:
let
  cfg = config.services.umami;
in
{
  imports = [
    ./secrets.nix
    ./backup.nix
  ];

  services.umami = {
    enable = true;

    settings = {
      APP_SECRET_FILE = config.sops.secrets.umami-app-secret.path;
      DISABLE_TELEMETRY = true;
    };
  };

  services.nginx = lib.mkIf cfg.enable {
    enable = true;

    virtualHosts."analytics.tietokilta.fi" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.settings.PORT}";
        # Umami derives visitor country from the forwarded client address
        recommendedProxySettings = true;
      };
    };
  };
}
