{
  inputs,
  config,
  lib,
  ...
}:
let
  lc = config.flake.lib.livingCode;
  c = lc.colors;
  bg = lc.mix;
  hunkTheme = {
    base = "github-dark-default";
    label = lc.label;
    background = c.base;
    panel = c.mantle;
    panelAlt = c.surface0;
    border = c.surface1;
    accent = c.teal;
    accentMuted = bg c.teal c.base 35;
    text = c.text;
    muted = c.subtext;
    addedBg = bg c.moss c.base 10;
    removedBg = bg c.flare c.base 10;
    movedAddedBg = bg c.steel c.base 10;
    movedRemovedBg = bg c.amber c.base 10;
    contextBg = c.base;
    addedContentBg = bg c.moss c.base 20;
    removedContentBg = bg c.flare c.base 20;
    contextContentBg = c.base;
    addedSignColor = c.moss;
    removedSignColor = c.flare;
    lineNumberBg = c.base;
    lineNumberFg = c.overlay;
    selectedHunk = c.surface0;
    badgeAdded = c.moss;
    badgeRemoved = c.flare;
    badgeNeutral = c.subtext;
    fileNew = c.moss;
    fileDeleted = c.flare;
    fileRenamed = c.steel;
    fileModified = c.amber;
    fileUntracked = c.comment;
    noteBorder = c.orchid;
    noteBackground = c.mantle;
    noteTitleBackground = c.surface1;
    noteTitleText = c.text;
  };
  # Syntax follows the VS Code theme; TOML text keeps its rule order.
  tokenColors =
    (builtins.fromJSON (builtins.readFile (lc.extra "vscode/themes/${lc.name}-color-theme.json")))
    .tokenColors;
  scopeRules = builtins.concatMap (
    rule:
    let
      scopes = if builtins.isList rule.scope then rule.scope else [ rule.scope ];
      color = rule.settings.foreground or "";
    in
    # Hunk accepts only opaque #rrggbb colors.
    if builtins.stringLength color == 7 then map (scope: { inherit scope color; }) scopes else [ ]
  ) tokenColors;
  # TOML rejects repeated keys; keep the last rule, which would win anyway.
  scopeLines = lib.concatLists (
    lib.imap0 (
      i: rule:
      lib.optional (
        !lib.any (later: later.scope == rule.scope) (lib.drop (i + 1) scopeRules)
      ) "${builtins.toJSON rule.scope} = \"${rule.color}\""
    ) scopeRules
  );
  themeLines = builtins.attrValues (
    builtins.mapAttrs (key: value: "${key} = ${builtins.toJSON value}") hunkTheme
  );
in
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
          bun build packages/hunk/src/main.tsx --target=bun --packages=external --outfile=packages/hunk/hunk.js
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib/hunk $out/bin $out/share/skills/hunk
          # Keep workspace sources and relative dependency links together:
          # external @hunk/* imports resolve to packages in this tree.
          cp package.json $out/lib/hunk/
          cp -R packages node_modules $out/lib/hunk/
          cp -R packages/hunk/skills/hunk-review packages/hunk/skills/hunk-extensions $out/share/skills/hunk/
          ln -s share/skills/hunk $out/skills
          cat > $out/bin/hunk <<EOF
          #!${pkgs.runtimeShell}
          export HUNK_INSTALL_SOURCE=nix
          exec ${bun}/bin/bun $out/lib/hunk/packages/hunk/hunk.js "\$@"
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
        theme = "${lc.name}"
        mode = "auto"
        agent_notes = true
        prompt_save_view_preferences = false

        [themes.${lc.name}]
        ${builtins.concatStringsSep "\n" themeLines}

        [themes.${lc.name}.syntax_scopes]
        ${builtins.concatStringsSep "\n" scopeLines}
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
