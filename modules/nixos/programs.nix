{ inputs, pkgs, ... }:
{
  programs = {
    fish.enable = true;
    dconf.enable = true;

    appimage = {
      enable = true;
      binfmt = true;
    };

    hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland;
    };
  };
}
