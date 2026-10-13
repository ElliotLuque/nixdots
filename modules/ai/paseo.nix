{ inputs, config, ... }:
let
  lc = config.flake.lib.livingCode;
  c = lc.colors;
  pluginId = "living-code-theme";
  theme = {
    id = lc.name;
    name = lc.label;
    appearance = "dark";
    colors = {
      background = c.base;
      foreground = c.text;
      raised = c.surface0;
      control = c.surface1;
      border = c.surface1;
      accent = c.teal;
      mutedForeground = c.subtext;
      ring = c.overlay;
    };
  };
in
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages = {
        paseo = pkgs.callPackage ./_paseo-package.nix { };
        # A directory plugin in the same shape as sleeyax/paseo-plugins' themes.
        paseo-living-code = pkgs.runCommand "paseo-living-code-0.0.1" { } ''
          mkdir -p "$out"
          cp ${
            pkgs.writeText "paseo-plugin.json" (
              builtins.toJSON {
                id = pluginId;
                description = "Adds ${lc.label} as a Paseo app theme.";
                requirements.paseo = ">=0.9.0";
              }
            )
          } "$out/paseo-plugin.json"
          cp ${
            pkgs.writeText "package.json" (
              builtins.toJSON {
                name = "@local/${pluginId}";
                private = true;
                version = "0.0.1";
                type = "module";
              }
            )
          } "$out/package.json"
          cp ${pkgs.writeText "index.client.ts" ''
            import type { PluginClientContext } from "@getpaseo/plugin/client";

            export default function contribute(client: PluginClientContext) {
              client.addTheme(${builtins.toJSON theme});
              return () => {};
            }
          ''} "$out/index.client.ts"
        '';
        paseo-configure-theme = pkgs.writeShellApplication {
          name = "paseo-configure-theme";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            python3 ${./_paseo-theme.py} \
              "''${PASEO_HOME:-$HOME/.paseo}/config.json" \
              ${pluginId} \
              ${config.packages.paseo-living-code}
          '';
        };
      };
    };

  flake.modules.homeManager.paseo =
    { pkgs, lib, ... }:
    let
      packages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [ packages.paseo ];
      # Keep config.json writable: pairing, credentials and UI settings belong to Paseo.
      home.activation.paseoTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${packages.paseo-configure-theme}/bin/paseo-configure-theme
      '';
    };
}
