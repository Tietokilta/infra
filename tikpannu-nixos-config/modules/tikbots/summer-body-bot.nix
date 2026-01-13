{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tikbots.summer-body-bot;
in
{
  sops = lib.mkIf cfg.enable {
    secrets.summer-body-bot-token = {
      sopsFile = ../secrets/summer-body-bot.yaml;
      owner = cfg.user;
    };

    templates.summer-body-bot-env = {
      owner = cfg.user;
      content = ''
        TELEGRAM_TOKEN=${config.sops.placeholder.summer-body-bot-token}
      '';
    };
  };

  services.tikbots.summer-body-bot = {
    enable = false;
    envFile = config.sops.templates.summer-body-bot-env.path;
    env = {
      COMPETITION_START_DATE = "2025-03-10";
      COMPETITION_END_DATE = "2025-04-14";
      REMINDER_TIME = "20:00";
      REMINDER_MSG = "Test msg";

      ALLOWED_DATES = "2025-03-16,2025-03-23,2025-03-30,2025-04-06,2025-04-13,2025-04-14";

      ADMINS = "6630183133";
      SECRET_MAX_USAGE = "2";
      SECRET_COMMANDS = "morgons,tekkers,bruhh,eztikwin,olirigged";
      SECRET_RESPONSE_MORGONS = "CAACAgQAAxkBAAEx6TRntf21UXd5vKti-tmP7oSPB1WXgAACSxEAAsDREFMHiuNvA_6CeDYE";
      SECRET_RESPONSE_TEKKERS = "CAACAgQAAxkBAAEyTQpnxa8xBgABIAItKq6loFJVvRUmmSkAAkYVAAKZf7BRbYns0SM3XcY2BA";
      SECRET_RESPONSE_BRUHH = "CAACAgQAAxkBAAEyYf1nyKfWF-H31K4mazxNCg7U8G_UJQACMgoAAoNO0FLxjHpQiCn2uDYE";
      SECRET_RESPONSE_EZTIKWIN = "CAACAgQAAxkBAAEyYgFnyKjLbiN0OR3toShD4gLnpyYG8AACixgAAl7NsVHEOfraUbDYmTYE";
      SECRET_RESPONSE_OLIRIGGED = "CAACAgQAAxkBAAEyYgtnyKoGFw9JBxis3jsjKOCDAr7yUAACaQ4AArpsAAFQ8DoNvXeNhK42BA";
    };
  };
}
