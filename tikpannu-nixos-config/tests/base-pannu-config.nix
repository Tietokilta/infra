{ pkgs, lib, ... }:
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
  imports = [
    ../modules
  ];

  services.discourse = {
    admin.passwordFile = lib.mkForce discourseAdminPassFile.outPath;
    mail.outgoing.passwordFile = lib.mkForce discourseSmtpPassFile.outPath;
  };

  services.tikbots = {
    summer-body-bot.envFile = lib.mkForce summerbodybotEnvFile.outPath;
    tikbot.envFile = lib.mkForce tikbotEnvFile.outPath;
    wappupokemonbot.envFile = lib.mkForce wappupokemonbotEnvFile.outPath;
  };

  system.stateVersion = "23.11";
}
