{ pkgs, ... }:
{
  stylix = {
    iconTheme = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      light = "Papirus";
      dark = "Papirus-Dark";
    };
    targets = {
      hyprland.enable = false;
      hyprlock.enable = false;
      kitty.enable = false;
      fish.enable = false;
      spicetify.enable = false;
      bat.enable = false;
      btop.enable = false;
      cava.enable = false;
      starship.enable = false;
      yazi.enable = false;
      rofi.enable = false;
    };
  };
}
