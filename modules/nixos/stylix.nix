{ pkgs, ... }:
{
  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    enable = true;
    autoEnable = true;

    image = ../../wallpaper/mocha/cottages-river.png;

    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Propo";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        desktop = 16;
        terminal = 14;
      };
    };

    cursor = {
      name = "Bibata-Original-Classic";
      size = 22;
      package = pkgs.bibata-cursors;
    };

    targets = {
      chromium.enable = false;
      console.enable = false;
      fish.enable = false;
      nixvim.enable = false;
      plymouth.enable = false;
      spicetify.enable = false;
    };
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
