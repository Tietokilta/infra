{
  pkgs,
  lib,
  ...
}:
let
  discourseAdminPassFile = pkgs.writeText "discourseAdminPassFile" "VerylongAdminpass1";
  discourseSmtpPassFile = pkgs.writeText "discourseSmtpPassFile" "VerylongMailpass1";
  summerbodybotEnvFile = pkgs.writeText "summerbodybotEnvFile" ''
    TELEGRAM_TOKEN=my-test-tg-token1
  '';
  tikbotEnvFile = pkgs.writeText "tikbotEnvFile" ''
    TELEGRAM_TOKEN=my-test-tg-token2
  '';
  wappupokemonbotEnvFile = pkgs.writeText "wappupokemonbotEnvFile" ''
    TELEGRAM_BOT_TOKEN=my-test-tg-token3
  '';
in
{
  # Anything that is to be included in the test VM only
  # should be inside the `virtualisation.vmVariant` block
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 3;
    };

    services.xserver = {
      enable = true;
      windowManager.openbox.enable = true;
      displayManager.startx.enable = true;

      xkb = {
        layout = "fi";
        variant = "nodeadkeys";
      };
    };
    console.keyMap = "fi";

    programs.firefox.enable = true;

    users.users.test = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "test";
    };

    disabledModules = [
      ../networking.nix
    ];
    networking = {
      extraHosts = ''
        127.0.0.1 pannu.tietokilta.fi
        127.0.0.1 vaalit.staging.tietokilta.fi
      '';
      networkmanager.enable = true;
    };

    services.discourse = {
      admin.passwordFile = lib.mkForce discourseAdminPassFile.outPath;
      mail.outgoing.passwordFile = lib.mkForce discourseSmtpPassFile.outPath;
    };

    services.tikbots = {
      summer-body-bot.envFile = lib.mkForce summerbodybotEnvFile.outPath;
      tikbot.envFile = lib.mkForce tikbotEnvFile.outPath;
      wappupokemonbot.envFile = lib.mkForce wappupokemonbotEnvFile.outPath;
    };
  }; # `virtualisation.vmVariant` ends here
}
