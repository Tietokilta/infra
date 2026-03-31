{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tik-backup;
in
{
  imports = [
    ./postgresql.nix
  ];

  options.services.tik-backup = {
    azure.enable = (lib.mkEnableOption "backing up of Azure data") // {
      default = cfg.enable;
      defaultText = lib.literalExpression ''
        config.services.tik-backup.enable
      '';
    };
  };

  config.assertions = [
    {
      assertion = cfg.azure.enable -> cfg.enable;
      message = ''
        `services.tik-backup.azure.enable` cannot be enabled without `services.tik-backup.enable`
      '';
    }
  ];
}
