{
  services.nginx.virtualHosts."_".locations."/" = {
    return = "404";
  };
}
