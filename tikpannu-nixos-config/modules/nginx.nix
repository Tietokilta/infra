{
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
