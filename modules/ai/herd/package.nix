{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      # Native menu integrations and worktree spacing fixes are pinned to the
      # upstream version in flake.lock.
      packages.herdr =
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [
              ./_worktree-tools/context-menu.patch
              ./_terminal-browser-menu.patch
              ./_sidebar-worktree-spacing.patch
            ];
          });

      checks.herdr-terminal-browser-menu = config.packages.herdr.overrideAttrs (_: {
        src = inputs.herdr;
        doCheck = true;
        # The mock plugin uses Herdr's normal per-user config/state directories.
        preCheck = ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
        '';
        cargoTestFlags = [
          "--bin"
          "herdr"
          "terminal_browser"
        ];
      });

      checks.herdr-sidebar-spacing = config.packages.herdr.overrideAttrs (_: {
        src = inputs.herdr;
        doCheck = true;
        preCheck = ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
        '';
        cargoTestFlags = [
          "--bin"
          "herdr"
          "row_gap"
        ];
      });

      checks.herdr-worktree-menu = config.packages.herdr.overrideAttrs (_: {
        # Upstream's packaging source omits fixtures required by Rust unit tests.
        src = inputs.herdr;
        doCheck = true;
        cargoTestFlags = [
          "--bin"
          "herdr"
          "merge_delete"
        ];
      });
    };
}
