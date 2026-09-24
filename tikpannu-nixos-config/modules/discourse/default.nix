{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./secrets.nix
    ./backup.nix
  ];

  services.discourse = {
    enable = true;
    hostname = "vaalit.tietokilta.fi";
    package = pkgs.discourse.overrideAttrs (old: {
      patches = old.patches or [ ] ++ [
        # taken from https://github.com/NixOS/nixpkgs/pull/556752/changes/0ad08425d206e052f95a3fa756538904738b1c0a
        # fixes being unable to change avatar images
        (pkgs.writeText "optimize-image-fix.patch" ''
          diff --git a/config/imagemagick/policy.xml b/config/imagemagick/policy.xml
          index a29d02c021b..8075d701fee 100644
          --- a/config/imagemagick/policy.xml
          +++ b/config/imagemagick/policy.xml
          @@ -41,5 +41,5 @@
             <!-- HISTOGRAM/INFO: Upload#calculate_dominant_color! -->
             <policy domain="coder" rights="read|write" pattern="{HISTOGRAM,INFO}"/>

          -  <policy domain="system" name="symlink" rights="none" pattern="follow"/>
          +  <policy domain="system" name="symlink" rights="read|write" pattern="follow"/>
           </policymap>
        '')
      ];
    });

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
}
