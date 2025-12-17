{
  config,
  ...
}:
{
  sops.secrets.summer-body-bot-envFile = {
    sopsFile = ../secrets/summer-body-bot.yaml;
    owner = config.services.tikbots.summer-body-bot.user;
  };

  services.tikbots.summer-body-bot = {
    enable = true;
    envFile = config.sops.secrets.summer-body-bot-envFile.path;
    env = {
      COMPETITION_START_DATE = "2025-03-10";
      COMPETITION_END_DATE = "2025-04-14";
      REMINDER_TIME = "20:00";
      REMINDER_MSG = "Test msg";

      ALLOWED_DATES = "2025-03-16,2025-03-23,2025-03-30,2025-04-06,2025-04-13,2025-04-14";

      ADMINS = "6630183133";
    };
  };
}
