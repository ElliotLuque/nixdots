{ inputs, config, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, lib, ... }:
    let
      herdr = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      c = config.flake.lib.livingCode.colors;
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
                name = "catppuccin"  # Base palette; every token below overrides it.

                # Transparent chrome, with distinct active and navigation row fills.
                [theme.custom]
                panel_bg = "reset"
                sidebar_bg = "reset"
                active_row_bg = "${c.surface1}"
                selection_bg = "${c.surface2}"
                accent = "${c.teal}"
                surface0 = "${c.surface0}"
                surface1 = "${c.surface1}"
                surface_dim = "${c.surface2}"
                overlay0 = "${c.comment}"
                overlay1 = "${c.subtext}"
                text = "${c.text}"
                subtext0 = "${c.text2}"
                mauve = "${c.subtext}"
                green = "${c.comment}"  # Idle is muted, not successful.
                yellow = "${c.amber}"  # Working.
                red = "${c.flare}"  # Blocked.
                blue = "${c.steel}"
                teal = "${c.moss}"  # Done.
                peach = "${c.copper}"

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
                key = "prefix+ctrl+g"
                type = "popup"
                command = "lazygit"
        				description = "lazygit"
                width = "95%"
                height = "90%"

                # The persistent server may not inherit SHELL from the attaching client.
                [[keys.command]]
                key = "prefix+shift+c"
                type = "popup"
                command = "exec ${pkgs.fish}/bin/fish -i"
                width = "80%"
                height = "80%"
      '';
    };
}
