{ config, ... }:
{
  flake.modules.homeManager.ai-clients =
    { pkgs, ... }:
    let
      # Include the upstream environment defaults when building T3 Connect.
      t3codeBase = pkgs.t3code.override {
        t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            cp .env.example .env
          '';
        });
      };
      # The Electron backend loads node-pty, whose prebuilt binary lacks an
      # RPATH for libstdc++. Keep this workaround until nixpkgs patches it.
      t3code = pkgs.symlinkJoin {
        name = "t3code-${t3codeBase.version}";
        paths = [ t3codeBase ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          # Otherwise t3code:// callbacks launch bare Electron, not T3 Code.
          for program in t3 t3code-desktop; do
            rm "$out/bin/$program"
            makeWrapper "${t3codeBase}/bin/$program" "$out/bin/$program" \
              --set T3CODE_DESKTOP_LAUNCHER_PATH "$out/bin/t3code-desktop" \
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
        pkgs.antigravity-cli
        pkgs.claude-code
        t3code
      ];
      # GIO and desktop portals need an explicit MIME association, not just
      # Electron's hidden, runtime-generated URL handler.
      xdg.desktopEntries.t3code = {
        name = "T3 Code (Beta)";
        exec = "${t3code}/bin/t3code-desktop %U";
        icon = "t3code";
        categories = [ "Development" ];
        mimeType = [ "x-scheme-handler/t3code" ];
        settings.StartupWMClass = "t3code";
      };
      xdg.mimeApps = {
        enable = true;
        associations.added."x-scheme-handler/t3code" = [ "t3code.desktop" ];
        defaultApplications."x-scheme-handler/t3code" = [ "t3code.desktop" ];
      };
    };
}
