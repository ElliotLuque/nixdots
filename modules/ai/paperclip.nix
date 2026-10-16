{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.paperclip = pkgs.callPackage ./_paperclip-package.nix { };
    };

  # Paperclip server as a user service. State (config, embedded Postgres,
  # secrets, workspaces) stays writable in ~/.paperclip; create it once with
  # `paperclipai onboard` before the service's first start.
  flake.modules.homeManager.paperclip =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.paperclip;
      home = "${config.home.homeDirectory}/.paperclip";
    in
    {
      home.packages = [ package ];

      # Mirrors the unit `paperclipai service install` would generate, using the
      # Nix-built CLI instead of a self-updating managed install.
      systemd.user.services.paperclipai = {
        Unit = {
          Description = "Paperclip AI (default)";
          After = [ "network.target" ];
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${lib.getExe package} run --instance default";
          Environment = [
            "PAPERCLIP_SERVICE_MANAGED=1"
            "PAPERCLIP_INSTANCE_ID=default"
            "PAPERCLIP_HOME=${home}"
            # Agents spawn the user's CLIs (claude, codex, pi, git, ...).
            "PATH=${
              lib.makeBinPath [ pkgs.systemd ]
            }:${config.home.homeDirectory}/.local/bin:${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
          ];
          WorkingDirectory = "%h";
          Restart = "always";
          RestartSec = 5;
          TimeoutStopSec = 300;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
