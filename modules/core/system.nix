{ ... }:
{
  flake.modules.nixos.system = { pkgs, ... }: {
    # Keep NixOS defaults: all local users may use the daemon; only root is
    # trusted. Hosts can narrow access through nix.settings, independently of identity.
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    environment.systemPackages = with pkgs; [
      wget
      git
      neovim
      vim
      unzip
      home-manager
    ];
    time = {
      timeZone = "Europe/Madrid";
      hardwareClockInLocalTime = false;
    };
    nixpkgs.config.allowUnfree = true;
    # Rebuild front-end: progress (nom), package diffs (nvd), --ask confirmation.
    programs.nh = {
      enable = true;
      # Weekly GC of old generations/unreferenced paths (replaces nix.gc).
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
    # stateVersion is deliberately set by each host, not by this feature.
  };
}
