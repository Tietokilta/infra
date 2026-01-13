{
  config,
  ...
}:
{
  imports = [
    ./secrets.nix
  ];

  services.discourse = {
    enable = true;
    hostname = "vaalit.tietokilta.fi";

    enableACME = config.services.discourse.hostname != "localhost";
    nginx.enable = true;

    admin = {
      email = "admin@tieto" + "kilta.fi";
      username = "admin";
      fullName = "Admin";
      passwordFile = config.sops.secrets.discourse-admin-password.path;
    };
    mail.outgoing = {
      username = "postmaster@vaalit" + ".tietokilta.fi";
      serverAddress = "smtp.eu.mailgun.org";
      port = 587;
      passwordFile = config.sops.secrets.discourse-mailgun-smtp-password.path;
    };
  };

  # Set env vars for discourse here
  systemd.services.discourse.environment = {
    UNICORN_WORKERS = "4";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@tieto" + "kilta.fi";
  };
}
