{ inputs, pkgs, ... }:
{
  programs = {
    fish.enable = true;
    dconf.enable = true;

    hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    };
  };
}
