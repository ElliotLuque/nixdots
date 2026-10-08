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

      # Keep root settings before the integrations' TOML tables/keybindings.
      xdg.configFile."herdr/config.toml".text = lib.mkBefore ''
        onboarding = false

        [theme]
        name = "catppuccin"

        # Transparent chrome, with distinct active and navigation row fills.
        [theme.custom]
        panel_bg = "reset"
        sidebar_bg = "reset"
        active_row_bg = "#313244"
        selection_bg = "#45475a"
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
        agent_panel_sort = "priority"

        [ui.sidebar.agents]
        row_gap = 0
        rows = [
          ["state_icon", {token = "terminal_title_stripped", dim = false}],
          [{token = "workspace", dim = true, bold = false}],
        ]

        [ui.toast]
        delivery = "system"

        [keys]
        prefix = "ctrl+a"
        workspace_picker = "prefix+w"
        switch_tab = "prefix+1..9"
        focus_pane_left = ["prefix+h", "prefix+left"]
        focus_pane_down = ["prefix+j", "prefix+down"]
        focus_pane_up = ["prefix+k", "prefix+up"]
        focus_pane_right = ["prefix+l", "prefix+right"]

        [keys.indexed]
        workspaces = "ctrl"
        agents = "ctrl+shift"

        # Explicitly exit the command shell when lazygit quits (including q).
        [[keys.command]]
        key = "ctrl+g"
        type = "popup"
        command = "${pkgs.lazygit}/bin/lazygit; exit"
        width = "95%"
        height = "90%"

        [[keys.command]]
        key = "prefix+shift+c"
        type = "popup"
        command = 'exec "$SHELL" -i'
        width = "80%"
        height = "80%"
      '';
    };
}
