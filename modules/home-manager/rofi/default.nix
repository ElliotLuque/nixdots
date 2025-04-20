{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = ./drun.rasi;

    extraConfig = {
      modi = "drun";
      show-icons = true;
    };
  };
}
