{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      plugin = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-worktree-tools";
        version = "0.1.0";
        src = ./_worktree-tools;
        dontBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp merge_delete.py $out/
          # Include Git without replacing the user's PATH (Git hooks may need it).
          makeWrapper ${pkgs.python3}/bin/python3 $out/bin/merge-delete \
            --prefix PATH : ${lib.makeBinPath [ pkgs.git ]} \
            --add-flags "$out/merge_delete.py"
          substitute herdr-plugin.toml $out/herdr-plugin.toml \
            --replace-fail '@command@' "$out/bin/merge-delete"
          runHook postInstall
        '';
      };
    in
    {
      packages.herdr-worktree-tools = plugin;
      checks.herdr-worktree-tools =
        pkgs.runCommand "herdr-worktree-tools-tests"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.git
            ];
          }
          ''
            export HOME="$TMPDIR/home"
            export GIT_CONFIG_NOSYSTEM=1
            export GIT_CONFIG_GLOBAL=/dev/null
            mkdir -p "$HOME"
            cp -R ${./_worktree-tools} tests
            chmod -R u+w tests
            cd tests
            python3 -m unittest -v
            touch "$out"
          '';
    };

  flake.modules.homeManager.herdr-merge-delete =
    { pkgs, lib, ... }:
    let
      packages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.activation.herdr-worktree-tools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${packages.herdr}/bin/herdr plugin link ${packages.herdr-worktree-tools} --enabled
      '';
    };
}
