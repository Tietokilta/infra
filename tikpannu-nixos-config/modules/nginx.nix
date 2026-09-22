{
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
