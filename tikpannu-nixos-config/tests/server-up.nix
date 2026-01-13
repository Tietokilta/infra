{ lib, ... }:
{
  name = "server-is-up";

  nodes = {
    pannu = {
      imports = [
        ./base-pannu-config.nix
      ];
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      virtualisation = {
        memorySize = 4096; # MiB
        cores = 4;
      };

      services.tikbots = {
        tikbot.enable = lib.mkForce false;
        summer-body-bot.enable = lib.mkForce false;
        wappupokemonbot.enable = lib.mkForce false;
      };
    };

    client =
      { nodes, ... }:
      {
        networking.extraHosts = ''
          ${nodes.pannu.networking.primaryIPAddress} pannu.tietokilta.fi
          ${nodes.pannu.networking.primaryIPAddress} vaalit.tietokilta.fi
        '';
      };
  };

  testScript = # python
    ''
      def assert_http_code(url, expected_http_code, extra_curl_args=""):
        command = f'curl -o /dev/null {extra_curl_args} --silent --fail --write-out "%{{http_code}}" {url}'
        print(f'Running "{command}"')
        _, http_code = client.execute(command)
        print(f'Got http_code: {http_code}, expected: {expected_http_code}')

        assert http_code == str(expected_http_code), f"expected http code {expected_http_code}, got {http_code}"

      start_all()

      pannu.wait_for_unit("discourse.service")
      # Discourse is 'active' before it's ready for connections
      pannu.succeed("timeout 120 journalctl -fu discourse.service | grep -m1 'worker=3 ready'")

      client.wait_for_unit("network.target")
      pannu.wait_for_open_port(80)
      # These should redirect to https
      assert_http_code("http://pannu.tietokilta.fi", 301)
      assert_http_code("http://pannu.tietokilta.fi/doesnt-exist", 301)
      assert_http_code("http://vaalit.tietokilta.fi", 301)

      pannu.wait_for_open_port(443)
      assert_http_code("https://pannu.tietokilta.fi", 404, extra_curl_args="--insecure")
      assert_http_code("https://pannu.tietokilta.fi/doesnt-exist", 404, extra_curl_args="--insecure")
      assert_http_code("https://vaalit.tietokilta.fi", 200, extra_curl_args="--insecure")
    '';
}
