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
          touch "$out"
        '';
    };
}
