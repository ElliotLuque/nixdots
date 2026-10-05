{ inputs, ... }:
{
  flake.modules.homeManager.herdr-worktrunk =
    { pkgs, lib, ... }:
    let
      herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      plugin = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-worktrunk";
        version = inputs.herdr-worktrunk.shortRev;
        src = inputs.herdr-worktrunk;
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R . $out/
          patchShebangs $out
          runHook postInstall
        '';
      };
    in
    {
      home.packages = [
        pkgs.worktrunk
        pkgs.fzf
        pkgs.jq
        pkgs.bash
      ];

      # Herdr owns a mutable registry shared with other plugins. Relink on
      # activation to refresh the cached manifest and Nix store path, without
      # replacing the registry or fetching anything at activation time.
      home.activation.herdr-worktrunk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${herdr}/bin/herdr plugin link ${plugin} --enabled
      '';
    };
}
