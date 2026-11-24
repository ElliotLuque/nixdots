{ inputs, config, ... }:
let
  modules = config.flake.modules;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      mkFixture =
        extraModules:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            modules.nixos.base
            {
              nixpkgs.hostPlatform = system;
              boot.isContainer = true;
              system.stateVersion = "24.11";
            }
          ]
          ++ extraModules;
        };
      plain = (mkFixture [ ]).config;
      managed = (mkFixture [ modules.nixos.network-manager ]).config;
      localSend = (mkFixture [ modules.nixos.localsend ]).config;
      outboundOnly =
        (mkFixture [
          modules.nixos.localsend
          { programs.localsend.openFirewall = false; }
        ]).config;
      campus = (mkFixture [ modules.nixos.campus-wifi ]).config;
      campusVpn =
        (mkFixture [
          modules.nixos.campus-vpn
          { networking.useHostResolvConf = false; }
        ]).config;
      campusVpnClient = pkgs.lib.findFirst (
        package: pkgs.lib.getName package == "upv-vpn"
      ) (throw "campus-vpn must install upv-vpn") campusVpn.environment.systemPackages;
      campusVpnConnections = campusVpn.services.strongswan-swanctl.swanctl.connections;
      campusVpnDns = campusVpnConnections.ALUMNO.children.ALUMNO-net.updown;
      sshClient = (mkFixture [ modules.nixos.ssh-client ]).config;
      sshServer = (mkFixture [ modules.nixos.ssh-server ]).config;
      mosh = (mkFixture [ modules.nixos.mosh ]).config;
      moshClosed =
        (mkFixture [
          modules.nixos.mosh
          { programs.mosh.openFirewall = false; }
        ]).config;
      identity = (mkFixture [ modules.nixos.elliot ]).config;
      mkHomeFixture =
        extraModules:
        (inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              home.username = "network-test";
              home.homeDirectory = "/home/network-test";
              home.stateVersion = "24.11";
            }
          ]
          ++ extraModules;
        }).config;
      plainHome = mkHomeFixture [ ];
      vpnHome = mkHomeFixture [ modules.homeManager.proton-vpn ];
      sshHome = mkHomeFixture [ modules.homeManager.ssh-client ];
      personalSshHome = mkHomeFixture [
        modules.homeManager.ssh-client
        {
          programs.ssh.settings.vps = {
            HostName = "vps.example.invalid";
            User = "admin";
            IdentityFile = "~/.ssh/id_ed25519";
            IdentitiesOnly = true;
          };
        }
      ];
    in
    {
      checks.networking-and-access =
        assert !plain.programs.localsend.enable;
        assert !plain.programs.mosh.enable;
        assert plain.networking.firewall.allowedUDPPortRanges == [ ];
        assert mosh.programs.mosh.enable;
        assert builtins.elem pkgs.mosh mosh.environment.systemPackages;
        assert !mosh.services.openssh.enable;
        assert mosh.networking.firewall.allowedTCPPorts == [ ];
        assert
          mosh.networking.firewall.allowedUDPPortRanges == [
            {
              from = 60000;
              to = 61000;
            }
          ];
        assert moshClosed.programs.mosh.enable;
        assert moshClosed.networking.firewall.allowedUDPPortRanges == [ ];
        assert !plain.services.strongswan-swanctl.enable;
        assert !plain.services.resolved.enable;
        assert plain.networking.networkmanager.ensureProfiles.profiles == { };
        assert plain.networking.firewall.allowedTCPPorts == [ ];
        assert plain.networking.firewall.allowedUDPPorts == [ ];
        assert managed.networking.networkmanager.enable;
        assert managed.networking.networkmanager.ensureProfiles.profiles == { };
        assert managed.networking.firewall.allowedTCPPorts == [ ];
        assert managed.networking.firewall.allowedUDPPorts == [ ];
        assert localSend.programs.localsend.enable;
        assert localSend.networking.firewall.allowedTCPPorts == [ 53317 ];
        assert localSend.networking.firewall.allowedUDPPorts == [ 53317 ];
        assert outboundOnly.programs.localsend.enable;
        assert outboundOnly.networking.firewall.allowedTCPPorts == [ ];
        assert outboundOnly.networking.firewall.allowedUDPPorts == [ ];
        assert campus.networking.networkmanager.enable;
        assert
          campus.networking.networkmanager.ensureProfiles.profiles.UPVNET."802-1x".password
          == "$CAMPUS_WIFI_PASSWORD";
        assert
          campus.networking.networkmanager.ensureProfiles.environmentFiles
          == [ "/etc/nixdots/campus-wifi.env" ];
        assert campus.networking.firewall.allowedTCPPorts == [ ];
        assert builtins.isString campus.system.build.toplevel.drvPath;
        assert campusVpn.networking.networkmanager.enable;
        assert campusVpn.services.resolved.enable;
        assert campusVpn.networking.networkmanager.dns == "systemd-resolved";
        assert campusVpn.services.strongswan-swanctl.enable;
        assert campusVpn.services.strongswan-swanctl.includes == [ "/etc/nixdots/upv-vpn.conf" ];
        assert campusVpn.services.strongswan-swanctl.swanctl.secrets.eap == { };
        assert campusVpn.services.strongswan-swanctl.swanctl.secrets.ike == { };
        assert campusVpn.systemd.services.strongswan-swanctl.wantedBy == [ ];
        assert
          campusVpn.systemd.services.strongswan-swanctl.unitConfig.ConditionPathExists
          == "/etc/nixdots/upv-vpn.conf";
        assert
          builtins.attrNames campusVpnConnections == [
            "ALUMNO"
            "ALUMNO-BIB"
            "UPVNET"
            "UPVNET-BIB"
          ];
        assert builtins.all (
          profile:
          let
            connection = campusVpnConnections.${profile};
          in
          connection.version == 2
          && connection.remote_addrs == [ "vpn.upv.es" ]
          && connection.proposals == [ "aes256-sha256-modp2048" ]
          && connection.encap
          && connection.local.user.auth == "eap-mschapv2"
          && connection.local.user.eap_id == null
          && connection.remote.gateway.auth == "psk"
          && connection.children."${profile}-net".start_action == "none"
        ) (builtins.attrNames campusVpnConnections);
        assert
          campusVpnConnections.ALUMNO.children.ALUMNO-net.remote_ts == [
            "158.42.0.0/16"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];
        assert campusVpnConnections.ALUMNO-BIB.children.ALUMNO-BIB-net.remote_ts == [ "0.0.0.0/0" ];
        assert campusVpnConnections.ALUMNO-BIB.children.ALUMNO-BIB-net.local_ts == [ "0.0.0.0/0" ];
        assert campusVpn.networking.firewall.allowedTCPPorts == [ ];
        assert campusVpn.networking.firewall.allowedUDPPorts == [ ];
        assert builtins.isString campusVpn.system.build.toplevel.drvPath;
        assert config.flake.nixosConfigurations.nixos-pc.config.services.strongswan-swanctl.enable;
        assert !config.flake.nixosConfigurations.nixos-laptop.config.services.strongswan-swanctl.enable;
        assert sshClient.programs.ssh.startAgent;
        assert !sshClient.services.openssh.enable;
        assert sshClient.networking.firewall.allowedTCPPorts == [ ];
        assert sshServer.services.openssh.enable;
        assert !sshServer.programs.ssh.startAgent;
        assert builtins.elem 22 sshServer.networking.firewall.allowedTCPPorts;
        assert plain.nix.settings.allowed-users == [ "*" ];
        assert identity.nix.settings.allowed-users == plain.nix.settings.allowed-users;
        assert identity.nix.settings.trusted-users == [ "root" ];
        assert builtins.isString identity.system.build.toplevel.drvPath;
        assert !(plainHome.systemd.user.services ? proton-vpn);
        assert vpnHome.systemd.user.services.proton-vpn.Install.WantedBy == [ "graphical-session.target" ];
        assert vpnHome.systemd.user.services.proton-vpn.Unit.PartOf == [ "graphical-session.target" ];
        assert builtins.elem pkgs.proton-vpn vpnHome.home.packages;
        assert builtins.isString vpnHome.home.activationPackage.drvPath;
        assert sshHome.programs.ssh.enable;
        assert !(sshHome.programs.ssh.settings ? vps);
        assert pkgs.lib.hasInfix "vps.example.invalid" personalSshHome.home.file.".ssh/config".text;
        pkgs.runCommand "networking-and-access-check" { } ''
          # --help parses strongswan.conf without needing a running daemon.
          STRONGSWAN_CONF=${campusVpn.environment.etc."strongswan.conf".source} \
            ${pkgs.lib.getExe campusVpn.services.strongswan-swanctl.package} --help > /dev/null
          ${pkgs.lib.getExe campusVpnClient} --help > help.txt
          grep -q ALUMNO-BIB help.txt
          if ${pkgs.lib.getExe campusVpnClient} connect INVALID; then
            echo 'Invalid VPN profiles must be rejected' >&2
            exit 1
          fi
          # Exercise the actual generated hook, without changing the build host.
          export calls="$PWD/dns-calls"
          resolvectl() { printf 'resolvectl %s\n' "$*" >> "$calls"; }
          nmcli() { printf 'nmcli %s\n' "$*" >> "$calls"; }
          export -f resolvectl nmcli
          export PLUTO_INTERFACE=eth-test
          export PLUTO_VERB=up-client
          for profile in ALUMNO UPVNET; do
            export PLUTO_CONNECTION="$profile-net"
            ${campusVpnDns}
            grep -Fx 'resolvectl dns eth-test 158.42.1.118 158.42.1.128' "$calls"
            grep -Fx 'resolvectl domain eth-test ~upv.es' "$calls"
            rm "$calls"
          done
          for profile in ALUMNO-BIB UPVNET-BIB; do
            export PLUTO_CONNECTION="$profile-net"
            ${campusVpnDns}
            grep -Fx 'resolvectl domain eth-test ~.' "$calls"
            rm "$calls"
          done
          export PLUTO_VERB=down-client
          ${campusVpnDns}
          grep -Fx 'resolvectl revert eth-test' "$calls"
          grep -Fx 'nmcli general reload dns-full' "$calls"
          touch "$out"
        '';
    };
}
