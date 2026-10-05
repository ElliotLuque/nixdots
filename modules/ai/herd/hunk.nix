{ inputs, ... }:
{
  flake.modules.homeManager.hunk-review =
    { pkgs, ... }:
    let
      herdr = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      # Hunk refuses watch mode with Bun 1.3.13 (watcher shutdown deadlock).
      # Remove this local override when nixpkgs ships Bun >= 1.3.14.
      bun = pkgs.bun.overrideAttrs (_: {
        version = "1.3.14";
        src = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-${
            {
              x86_64-linux = "linux-x64-baseline";
              aarch64-linux = "linux-aarch64";
              aarch64-darwin = "darwin-aarch64";
            }
            .${pkgs.stdenv.hostPlatform.system}
          }.zip";
          hash =
            {
              x86_64-linux = "sha256-oGOQiuCLeFLKEJObvcbO7T3avOj7lALc6D1l1zs25sc=";
              aarch64-linux = "sha256-on/7Y6gxA3WDbg1vZorhf6jY0YuIw3yCHGUzGXOhmjs=";
              aarch64-darwin = "sha256-2LliIYKK1vl6x6wKt+lYcjQa92MAHogD6CZ2UsJlJiA=";
            }
            .${pkgs.stdenv.hostPlatform.system};
        };
      });
      hunk = (pkgs.hunk.override { inherit bun; }).overrideAttrs (_: {
        # The Bun 1.3.14 compiled executable segfaults in this Nix build.
        # Run the same bundled source with Bun instead of embedding the runtime.
        buildPhase = ''
          runHook preBuild
          bun build src/main.tsx --target=bun --packages=external --outfile=hunk.js
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib/hunk $out/bin $out/share/skills/hunk
          cp hunk.js package.json $out/lib/hunk/
          ln -s ${pkgs.hunk.node_modules}/node_modules $out/lib/hunk/node_modules
          cp -R skills/hunk-review skills/hunk-extensions $out/share/skills/hunk/
          cat > $out/bin/hunk <<EOF
          #!${pkgs.runtimeShell}
          exec ${bun}/bin/bun $out/lib/hunk/hunk.js "\$@"
          EOF
          chmod +x $out/bin/hunk
          runHook postInstall
        '';
      });
    in
    {
      home.packages = [ hunk ];
      home.file.".pi/agent/extensions/hunk.ts".text =
        builtins.replaceStrings [ "@herdr@" "@hunk@" ] [ "${herdr}/bin/herdr" "${hunk}/bin/hunk" ]
          (builtins.readFile ./_hunk.ts);
      home.file.".agents/skills/hunk-review".source = "${hunk}/share/skills/hunk/hunk-review";

      xdg.configFile."hunk/config.toml".text = ''
        theme = "catppuccin-mocha"
        mode = "auto"
        agent_notes = true
        prompt_save_view_preferences = false
      '';
      xdg.configFile."herdr/config.toml".text = ''
        [[keys.command]]
        key = "prefix+d"
        type = "popup"
        command = "${hunk}/bin/hunk diff --watch --agent-notes"
        width = "95%"
        height = "90%"
      '';
    };
}
