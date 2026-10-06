{ inputs, config, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, lib, ... }:
    {
      imports = with config.flake.modules.homeManager; [
        hunk-review
        herdr-radar
        herdr-merge-delete
      ];

      home.packages = [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr ];

      # Keep root settings before the integrations' TOML tables/keybindings.
      xdg.configFile."herdr/config.toml".text = lib.mkBefore ''
        onboarding = false

        [theme]
        name = "catppuccin"

        # Catppuccin Mocha: keep chrome opaque and distinguish active spaces
        # from the Navigate-mode cursor without changing agent status colours.
        [theme.custom]
        sidebar_bg = "#181825"
        active_row_bg = "#313244"
        selection_bg = "#45475a"
        surface_dim = "#6c7086"
        overlay0 = "#a6adc8"
        overlay1 = "#bac2de"

        [ui]
        status_indicators = "symbols"
        pane_borders = "always"
        pane_outer_borders = true

        [ui.toast]
        delivery = "system"
      '';
    };
}
