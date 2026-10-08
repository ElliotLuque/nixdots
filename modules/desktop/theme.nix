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
  flake.modules.homeManager.theme = { pkgs, config, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    xdg.dataFile."wallpapers".source = ../../wallpaper/mocha;
    programs.rofi.settings.font =
      "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";
      gtk.icon.enable = false;
      kvantum.enable = false;
      hyprlock.enable = false;
      # Move gui.authorColors into gui.theme without changing the rest of the YAML.
      sources.lazygit =
        inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system}.lazygit.overrideAttrs
          (old: {
            postInstall = (old.postInstall or "") + ''
              sed -i '/^  authorColors:/,+1s/^/  /' "$out"/*/*.yml
            '';
          });
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
        rofi.enable = false; # Catppuccin owns Rofi; avoid Stylix's deprecated font option.
      };
    };
  };
}
