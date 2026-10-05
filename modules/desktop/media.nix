{ inputs, ... }:
{
  flake.modules.homeManager.media = { pkgs, ... }: {
    imports = [ inputs.spicetify-nix.homeManagerModules.default ];
    programs.cava.enable = true;
    programs.ncspot = {
      enable = true;
      settings."[theme]" = {
        background = "#1E1E2E";
        primary = "#CDD6F4";
        secondary = "#CBA6F7";
        title = "#CBA6F7";
        playing = "#89B4FA";
        playing_selected = "#F9E2AF";
        playing_bg = "#1E1E2E";
        highlight = "#1E1E2E";
        highlight_bg = "#CBA6F7";
        error = "#F38BA8";
        error_bg = "#1E1E2E";
        statusbar = "#1E1E2E";
        statusbar_progress = "#A6E3A1";
        statusbar_bg = "#A6E3A1";
        cmdline = "#CDD6F4";
        cmdline_bg = "#181825";
      };
    };
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
        theme = spicePkgs.themes.catppuccin;
        colorScheme = "mocha";
      };
  };
}
