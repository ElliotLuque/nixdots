{ inputs, ... }:
{
  perSystem = { pkgs, config, ... }: {
    packages.terminal-browser = pkgs.callPackage ./_terminal-browser-package.nix { };
    packages.terminal-browser-herdr = pkgs.runCommand "terminal-browser-herdr-0.1.1" { } ''
      mkdir -p $out
      cat > $out/herdr-plugin.toml <<EOF
      id = "zenbu-labs.terminal-browser"
      name = "Terminal Browser"
      version = "0.1.1"
      min_herdr_version = "0.8.2"
      description = "Open a browser inside herdr"
      platforms = ["linux"]

      [[actions]]
      id = "open-split"
      title = "Open terminal-browser (right split)"
      description = "Split the focused pane and open terminal-browser in it"
      contexts = ["global"]
      command = ["${config.packages.terminal-browser}/bin/terminal-browser", "open", "--split", "right"]
      EOF
    '';
    checks.terminal-browser =
      pkgs.runCommand "terminal-browser-check"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          export HOME=$TMPDIR/home
          mkdir -p "$HOME"
          ${config.packages.terminal-browser}/bin/terminal-browser --version | grep -F '0.13.4'
          ${config.packages.terminal-browser}/bin/terminal-browser --help > help.txt
          grep -F 'action' help.txt
          ${config.packages.terminal-browser}/lib/terminal-browser/agent-browser/bin/agent-browser --version
          ELECTRON_RUN_AS_NODE=1 ${config.packages.terminal-browser}/lib/terminal-browser/electron/pixel \
            -e 'require(process.argv[1])' \
            ${config.packages.terminal-browser}/lib/terminal-browser/browser/node_modules/@zenbu-labs/pixel-native-*/pixel.node
          python3 - '${config.packages.terminal-browser}' '${config.packages.terminal-browser-herdr}' <<'PY'
          import pathlib, sys, tomllib
          browser, plugin = map(pathlib.Path, sys.argv[1:])
          skill = browser / 'lib/terminal-browser/skills/default/terminal-browser/SKILL.md'
          assert 'name: terminal-browser' in skill.read_text()
          manifest = tomllib.loads((plugin / 'herdr-plugin.toml').read_text())
          assert 'build' not in manifest
          assert manifest['actions'][0]['command'] == [str(browser / 'bin/terminal-browser'), 'open', '--split', 'right']
          PY
          touch $out
        '';
  };

  flake.modules.homeManager.terminal-browser =
    { pkgs, ... }:
    let
      browser = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.terminal-browser;
    in
    {
      home.packages = [ browser ];
      # Pi discovers ~/.agents/skills natively; no Claude-only plugin is required.
      home.file.".agents/skills/terminal-browser".source =
        "${browser}/lib/terminal-browser/skills/default/terminal-browser";
    };

  flake.modules.homeManager.terminal-browser-herdr =
    { pkgs, lib, ... }:
    let
      packages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.self.modules.homeManager.terminal-browser ];
      home.activation.terminal-browser-herdr = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${packages.herdr}/bin/herdr plugin link ${packages.terminal-browser-herdr} --enabled
      '';
    };
}
