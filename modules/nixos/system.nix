{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
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
  system.stateVersion = "24.11";
}
