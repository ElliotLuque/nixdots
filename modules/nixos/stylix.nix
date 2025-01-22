{ pkgs, lib, inputs, config, ... }:
{
  stylix = {  
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    enable = true;
    autoEnable = false;

    image = ../../wallpaper/mocha/galaxy-waves.jpg ;

    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    cursor.name = "Bibata-Original-Classic";
    cursor.size = 22;
    cursor.package = pkgs.bibata-cursors;

    targets.gtk.enable = true;
  };
  # wayland.windowManager.hyprland.settings.general."col.active-border" =
  #   lib.mkForce "rgb(${config.stylix.base16Scheme.base0F})";
  #
  # wayland.windowManager.hyprland.settings.general."col.inactive-border" =
  #   lib.mkForce "rgb(${config.stylix.base16Scheme.base02})";
  #
  # wayland.windowManager.hyprland.settings.decoration.shadow."color" =
  #   lib.mkForce "rgba(${config.stylix.base16Scheme.base0F}bb)";
  #
  # wayland.windowManager.hyprland.settings.decoration.shadow."color_inactive" =
  #   lib.mkForce "rgba(${config.stylix.base16Scheme.base02}aa)";
}
