{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      # Plugin v1 cannot extend the native context menu. Keep this patch small
      # and pinned to the upstream version in flake.lock.
      packages.herdr =
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [ ./_worktree-tools/context-menu.patch ];
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
