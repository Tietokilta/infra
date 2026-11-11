{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.tik.gatus;

  reportUnitName = name: "${name}-gatus-report";

  # Takes `success` or `failure` (the template instance) as its only argument.
  # Expects the token in the GATUS_TOKEN environment variable.
  mkReportScript =
    name: alert:
    pkgs.writeShellApplication {
      name = reportUnitName name;
      runtimeInputs = [ pkgs.curl ];
      text = ''
        case "$1" in
          success) result=(--url-query "success=true") ;;
          failure) result=(--url-query "success=false" --url-query "error="${lib.escapeShellArg alert.error}) ;;
          *)
            echo "Unknown result '$1', expected 'success' or 'failure'" >&2
            exit 2
            ;;
        esac

        curl \
          --fail-with-body \
          --silent \
          --show-error \
          -X POST \
          -H "Authorization: Bearer $GATUS_TOKEN" \
          "''${result[@]}" \
          ${lib.escapeShellArg "${cfg.url}/api/v1/endpoints/${alert.endpoint}/external"}
      '';
    };

  alertModule =
    { name, ... }:
    {
      options = {
        endpoint = lib.mkOption {
          description = "Key of the Gatus external endpoint, `<group>_<name>`.";
          type = lib.types.str;
          example = "_tikpannu-update";
        };
        error = lib.mkOption {
          description = "Error message sent to Gatus when the service fails.";
          type = lib.types.str;
          default = "${name} failed, see journalctl -u ${name}";
          defaultText = lib.literalExpression ''"<name> failed, see journalctl -u <name>"'';
        };
      };
    };
in
{
  options.tik.gatus = {
    alertServices = lib.mkOption {
      description = ''
        Systemd services (without `.service`) whose success and failure are
        reported to a Gatus external endpoint.
      '';
      type = lib.types.attrsOf (lib.types.submodule alertModule);
      default = { };
      example = {
        update-host.endpoint = "_tikpannu-update";
      };
    };

    url = lib.mkOption {
      description = "Base URL of the Gatus instance.";
      type = lib.types.str;
      default = "https://status.tietokilta.fi";
    };
  };

  config = lib.mkIf (cfg.alertServices != { }) {
    assertions = lib.mapAttrsToList (name: _: {
      assertion = !(lib.hasInfix "@" name) && !(lib.hasSuffix ".service" name);
      message = "tik.gatus.alertServices.${name}: use a plain service name, without `@` or `.service`";
    }) cfg.alertServices;

    sops.secrets.gatus-token = { };
    sops.templates.gatus-token-envfile.content = ''
      GATUS_TOKEN="${config.sops.placeholder.gatus-token}"
    '';

    systemd.services = lib.concatMapAttrs (name: alert: {
      ${name} = {
        onSuccess = [ "${reportUnitName name}@success.service" ];
        onFailure = [ "${reportUnitName name}@failure.service" ];
      };

      "${reportUnitName name}@" = {
        description = "Report %i of ${name}.service to Gatus";
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          EnvironmentFile = config.sops.templates.gatus-token-envfile.path;
          ExecStart = "${lib.getExe (mkReportScript name alert)} %i";
        };
      };
    }) cfg.alertServices;
  };
}
