{ inputs, config, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, lib, ... }:
    let
      herdr = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
    in
    {
      imports = with config.flake.modules.homeManager; [
        hunk-review
        terminal-browser-herdr
        herdr-merge-delete
      ];

      home.packages = [ herdr ];

      # Local plugin registrations outlive the modules that originally linked them.
      # Unlink is idempotent and leaves plugin configuration data intact.
      home.activation.herdr-remove-retired-plugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        for plugin in herdr-agent-quota hhdebb.herdr-radar worktrunk; do
          run ${herdr}/bin/herdr plugin unlink "$plugin"
        done
      '';

      # Leave agent sidebar rows unset so Herdr uses its built-in layout.
      # Keep root settings before the integrations' TOML tables/keybindings.
      xdg.configFile."herdr/config.toml".text = lib.mkBefore ''
        onboarding = false

        [theme]
        name = "catppuccin"

        # Catppuccin foregrounds without painted chrome/row backgrounds.
        # Focus and navigation remain visible through text styling.
        [theme.custom]
        panel_bg = "reset"
        sidebar_bg = "reset"
        active_row_bg = "reset"
        selection_bg = "reset"
        accent = "#89b4fa"
        surface_dim = "#45475a"
        overlay0 = "#9399b2"
        overlay1 = "#bac2de"
        mauve = "#a6adc8"
        green = "#9399b2"
        yellow = "#f9e2af"
        red = "#f38ba8"
        teal = "#a6e3a1"

        [ui]
        status_indicators = "symbols"
        pane_borders = "auto"
        pane_outer_borders = true

        [ui.sidebar.spaces]
        # The client patch applies this gap to nested worktrees too.
        row_gap = 1

        [ui.toast]
        delivery = "system"
      '';
    };
}
