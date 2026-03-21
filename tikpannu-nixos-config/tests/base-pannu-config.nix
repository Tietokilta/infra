{
  config,
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

  resticPassFile = pkgs.writeText "resticPassFile" ''
    veryStrongResticPass1
  '';

  # default is 100, mkForce is 50. Allow using mkForce in specific tests
  mkWeakForce = lib.mkOverride 90;
in
{
  imports = [ ../modules ];

  services.discourse = {
    enable = mkWeakForce false;
    admin.passwordFile = mkWeakForce discourseAdminPassFile.outPath;
    mail.outgoing.passwordFile = mkWeakForce discourseSmtpPassFile.outPath;
  };

  services.tikbots = {
    summer-body-bot = {
      enable = mkWeakForce false;
      envFile = mkWeakForce summerbodybotEnvFile.outPath;
    };
    tikbot = {
      enable = mkWeakForce false;
      envFile = mkWeakForce tikbotEnvFile.outPath;
    };
    wappupokemonbot = {
      enable = mkWeakForce false;
      envFile = mkWeakForce wappupokemonbotEnvFile.outPath;
    };
  };

  services.tik-backup.enable = mkWeakForce false;
  services.restic.backups.tik-backup = lib.mkIf config.services.tik-backup.enable {
    passwordFile = mkWeakForce resticPassFile.outPath;
  };

  system.stateVersion = "23.11";
}
