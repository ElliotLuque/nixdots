{ inputs, ... }:
{
  flake.modules.nixos.theme = { pkgs, ... }: {
    imports = [
      inputs.stylix.nixosModules.stylix
      inputs.catppuccin.nixosModules.catppuccin
    ];
    catppuccin = {
      enable = true;
      autoEnable = false;
    };
    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
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
  };
  flake.modules.homeManager.theme = { pkgs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    xdg.dataFile."wallpapers".source = ../../wallpaper/mocha;
    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";
      gtk.icon.enable = false;
      kvantum.enable = false;
      hyprlock.enable = false;
    };
    stylix = {
      icons = {
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
        opencode.enable = false; # Let Catppuccin own OpenCode's TUI theme.
      };
    };
  };
}
