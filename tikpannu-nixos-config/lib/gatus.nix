{ pkgs, lib }:
let
  # Shell command that pushes a result to a Gatus external endpoint.
  # Expects the token in the GATUS_TOKEN environment variable.
  mkHeartbeatCommand =
    {
      endpoint,
      success,
      error ? "unknown",
    }:
    /* bash */ ''
      ${lib.getExe pkgs.curl} \
        --fail-with-body \
        --silent \
        --show-error \
        -X POST \
        -H "Authorization: Bearer ''${GATUS_TOKEN}" \
        --url-query "success=${lib.boolToString success}" \
        --url-query "error=${error}" \
        https://status.tietokilta.fi/api/v1/endpoints/${endpoint}/external
    '';
in
{
  # Oneshot service that pushes a result to a Gatus external endpoint, meant to
  # be started from `onSuccess`/`onFailure` of the monitored unit.
  # `environmentFile` must set GATUS_TOKEN.
  mkHeartbeatService =
    {
      endpoint,
      success,
      error ? "unknown",
      environmentFile,
      serviceConfig ? { },
    }:
    {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = environmentFile;
        ExecStart = mkHeartbeatCommand { inherit endpoint success error; };
      }
      // serviceConfig;
    };
}
