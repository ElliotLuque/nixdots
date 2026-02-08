{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = ./drun.rasi;

    extraConfig = {
      modi = "drun";
      show-icons = true;
    };
  };
}
