{ inputs, config, ... }:
let
  c = config.flake.lib.livingCode.colors;
in
{
  flake.modules.homeManager.media = { pkgs, lib, ... }: {
    imports = [ inputs.spicetify-nix.homeManagerModules.default ];
    programs.cava.enable = true;
    programs.ncspot.enable = true; # Stylix themes ncspot from the base16 scheme.
    programs.spicetify =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        enable = true;
        enabledExtensions = with spicePkgs.extensions; [
          loopyLoop
          hidePodcasts
        ];
        enabledCustomApps = with spicePkgs.apps; [
          reddit
          lyricsPlus
        ];
        enabledSnippets = [ ];
        # Same color.ini slots as Stylix's target, mapped from the full palette.
        theme = {
          name = "living-code";
          src = pkgs.writeTextFile {
            name = "color.ini";
            destination = "/color.ini";
            text = lib.generators.toINI { } {
              base = lib.mapAttrs (_: lib.removePrefix "#") {
                text = c.text;
                subtext = c.subtext;
                main = c.base;
                main-elevated = c.mantle;
                highlight = c.surface1;
                highlight-elevated = c.surface2;
                sidebar = c.crust;
                player = c.mantle;
                card = c.surface0;
                shadow = c.crust;
                selected-row = c.text2;
                button = c.teal;
                button-active = c.mint;
                button-disabled = c.overlay;
                tab-active = c.surface1;
                notification = c.surface1;
                notification-error = c.flare;
                equalizer = c.moss;
                misc = c.surface2;
              };
            };
          };
          sidebarConfig = false;
        };
        colorScheme = "base";
      };
  };
}
