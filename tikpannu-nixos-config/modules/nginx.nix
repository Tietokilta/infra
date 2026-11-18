{
  imports = [
    (
      { lib, ... }:
      {
        options.services.nginx.virtualHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              config = {
                http2 = lib.mkForce false;
                http3 = lib.mkForce false;
                quic = lib.mkForce false;
              };
            }
          );
        };
      }
    )
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@tieto" + "kilta.fi";
  };

  services.nginx.virtualHosts = {
    "pannu.tietokilta.fi" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        return = "404";
      };
    };

    "_".locations."/" = {
      return = "301 https://pannu.tietokilta.fi";
    };
  };
}
