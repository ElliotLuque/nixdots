{ ... }:
{
  # Personal desktop VPN client. Import for selected users on selected hosts,
  # not as part of every desktop or headless AI environment.
  flake.modules.homeManager.proton-vpn = { pkgs, lib, ... }: {
    home.packages = [ pkgs.proton-vpn ];
    systemd.user.services.proton-vpn = {
      Unit = {
        Description = "Proton VPN desktop client";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe pkgs.proton-vpn;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
