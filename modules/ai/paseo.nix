{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages = {
        paseo = pkgs.callPackage ./_paseo-package.nix { };
        paseo-catppuccin = pkgs.runCommand "paseo-catppuccin-0.0.1" { } ''
          mkdir -p "$out"
          cp -r ${
            pkgs.fetchzip {
              url = "https://github.com/sleeyax/paseo-plugins/archive/41ff25de85931953ace4daa1a7923e20823514c5.tar.gz";
              hash = "sha256-HWS+Z/hd/zGlAN4p+zCHcQUs29X/xLL5PL2LJ2u+APc=";
            }
          }/plugins/catppuccin-theme/. "$out/"
        '';
        paseo-configure-catppuccin = pkgs.writeShellApplication {
          name = "paseo-configure-catppuccin";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            python3 ${./_paseo-catppuccin.py} \
              "''${PASEO_HOME:-$HOME/.paseo}/config.json" \
              ${config.packages.paseo-catppuccin}
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
      home.activation.paseoCatppuccin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${packages.paseo-configure-catppuccin}/bin/paseo-configure-catppuccin
      '';
    };
}
