{ config, ... }:
{
  flake.modules.homeManager.ai-clients =
    { pkgs, ... }:
    let
      # The Electron backend loads node-pty, whose prebuilt binary lacks an
      # RPATH for libstdc++. Keep this workaround until nixpkgs patches it.
      t3code = pkgs.symlinkJoin {
        name = "t3code-${pkgs.t3code.version}";
        paths = [ pkgs.t3code ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          for program in t3 t3code-desktop; do
            rm "$out/bin/$program"
            makeWrapper "${pkgs.t3code}/bin/$program" "$out/bin/$program" \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
          done
        '';
      };
    in
    {
      imports = with config.flake.modules.homeManager; [
        pi
        herdr
        opencode
        paseo
        agent-skills
      ];
      programs.codex.enable = true;
      home.packages = [
        pkgs.claude-code
        t3code
      ];
    };
}
