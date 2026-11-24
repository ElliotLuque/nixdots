{ config, ... }:
let
  modules = config.flake.modules;
in
{
  # UPV's IKEv2 service is separate from both campus Wi-Fi and Proton VPN.
  flake.modules.nixos.campus-vpn =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      strongswan = config.services.strongswan-swanctl.package;
      profiles = [
        "ALUMNO"
        "ALUMNO-BIB"
        "UPVNET"
        "UPVNET-BIB"
      ];
      dnsHook = pkgs.writeShellApplication {
        name = "upv-vpn-dns";
        runtimeInputs = [
          pkgs.systemd
          pkgs.networkmanager
        ];
        text = ''
          case "''${PLUTO_VERB:-}" in
            up-client)
              resolvectl dns "$PLUTO_INTERFACE" 158.42.1.118 158.42.1.128
              # updown receives the CHILD_SA name, e.g. ALUMNO-BIB-net.
              if [[ "$PLUTO_CONNECTION" == *-BIB-net ]]; then
                resolvectl domain "$PLUTO_INTERFACE" '~.'
              else
                resolvectl domain "$PLUTO_INTERFACE" '~upv.es'
              fi
              ;;
            down-client)
              resolvectl revert "$PLUTO_INTERFACE"
              nmcli general reload dns-full
              ;;
          esac
        '';
      };
      client = pkgs.writeShellApplication {
        name = "upv-vpn";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.systemd
          strongswan
        ];
        text = builtins.readFile ./upv-vpn.sh;
      };
    in
    {
      imports = [ modules.nixos.network-manager ];
      services.resolved.enable = true;
      services.strongswan-swanctl = {
        enable = true;
        # Only the path enters the store. Identity/password/PSK are read at runtime.
        includes = [ "/etc/nixdots/upv-vpn.conf" ];
        strongswan.extraConfig = ''
          charon {
            plugins {
              resolve {
                load = no
              }
            }
          }
        '';
        swanctl.connections = lib.genAttrs profiles (profile: {
          version = 2;
          remote_addrs = [ "vpn.upv.es" ];
          proposals = [ "aes256-sha256-modp2048" ];
          vips = [ "0.0.0.0" ];
          dpd_delay = "60s";
          encap = true;
          fragmentation = "yes";
          local.user = {
            auth = "eap-mschapv2";
            id = profile;
            # eap_id is merged from the private runtime include.
          };
          remote.gateway = {
            auth = "psk";
            id = profile;
          };
          children."${profile}-net" = {
            local_ts = if lib.hasSuffix "-BIB" profile then [ "0.0.0.0/0" ] else [ "dynamic" ];
            remote_ts =
              if lib.hasSuffix "-BIB" profile then
                [ "0.0.0.0/0" ]
              else
                [
                  "158.42.0.0/16"
                  # The guide writes 10.10.0.0/8; its canonical network is 10.0.0.0/8.
                  "10.0.0.0/8"
                  "172.16.0.0/12"
                  "192.168.0.0/16"
                ];
            updown = lib.getExe dnsHook;
            esp_proposals = [ "aes256-sha256-modp2048" ];
            dpd_action = "restart";
            # Do not initiate a 2FA request when loading/rebuilding/booting.
            start_action = "none";
          };
        });
      };
      environment.systemPackages = [
        strongswan
        client
      ];
      systemd.services.strongswan-swanctl = {
        wantedBy = lib.mkForce [ ];
        after = [
          "NetworkManager.service"
          "systemd-resolved.service"
        ];
        requires = [
          "NetworkManager.service"
          "systemd-resolved.service"
        ];
        unitConfig.ConditionPathExists = "/etc/nixdots/upv-vpn.conf";
        # Restore NetworkManager's DNS even if charon exits without running updown.
        serviceConfig.ExecStopPost = "${pkgs.networkmanager}/bin/nmcli general reload dns-full";
      };
    };
}
