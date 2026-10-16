{ inputs, lib, ... }:
let
  # One flavour selects every themed program. Values come from the theme's
  # canonical palette, so a living-code update needs no copied hex here.
  flavor = "night";
  src = inputs.living-code;
  scheme = (builtins.fromJSON (builtins.readFile "${src}/palette.json")).${flavor};
  colors = lib.mapAttrs (_: c: c.hex) scheme.colors;
  livingCode = {
    inherit flavor src colors;
    name = "living-code-${flavor}";
    label = scheme.name;
    roles = lib.mapAttrs (_: name: colors.${name}) scheme.roles;
    inherit (scheme) ansi;
    extra = path: "${src}/extras/${path}";
    # Opaque `pct`% blend of `fg` over `bg`, for UIs without alpha support.
    mix =
      fg: bg: pct:
      let
        channel = hex: i: lib.fromHexString (builtins.substring (1 + 2 * i) 2 hex);
        blend = i: (channel fg i * pct + channel bg i * (100 - pct) + 50) / 100;
        toHex = n: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString n));
      in
      "#"
      + lib.concatMapStrings (i: toHex (blend i)) [
        0
        1
        2
      ];
  };
in
{
  flake.lib = { inherit livingCode; };

  flake.modules.nixos.theme = { pkgs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];
    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = livingCode.extra "base16/${livingCode.name}.yaml";
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
        fish.enable = false;
        nixvim.enable = false; # Neovim is themed by the external nixvim flake.
        plymouth.enable = false; # boot-workstation keeps the firmware (bgrt) splash.
        spicetify.enable = false; # media.nix themes Spotify from the full palette.
      };
    };
  };

  flake.modules.homeManager.theme = { pkgs, config, ... }: {
    xdg.dataFile."wallpapers".source = ../../wallpaper/mocha;
    programs.rofi.settings.font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
    stylix = {
      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        light = "Papirus";
        dark = "Papirus-Dark";
      };
      # Programs with upstream living-code themes use them instead of the
      # 16-colour approximation; see session.nix and shell/tools.nix.
      targets = {
        hyprland.enable = false; # Configure Hyprland explicitly; borders are disabled.
        hyprlock.enable = false; # hyprlock.nix uses the palette directly.
        kitty.enable = false;
        fish.enable = false; # Fish uses the terminal's ANSI palette.
        spicetify.enable = false;
        bat.enable = false;
        btop.enable = false;
        lazygit.enable = false;
        starship.enable = false;
        rofi.enable = false; # Avoid Stylix's deprecated font option.
      };
    };
  };
}
