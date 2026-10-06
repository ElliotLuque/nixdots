{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.herdr-radar = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-radar";
        version = "1.4.2";
        src = inputs.herdr-radar;
        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.nodejs
        ];
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R bin lib dist herdr-plugin.toml LICENSE $out/
          chmod -R u+w $out

          # Home Manager owns config and fonts; never run upstream's first-run
          # installer or let popup actions write through a Nix store symlink.
          substituteInPlace $out/lib/setup.js --replace-fail \
            'function ensure({ force = false } = {}) {' \
            'function ensure({ force = false } = {}) { return [];'
          substituteInPlace $out/lib/managed-config.js --replace-fail \
            'function checkedWrite(file, next, saved) {' \
            'function checkedWrite(file, next, saved) { return "Herdr config is managed by Nix; change the Home Manager configuration instead.";'
          substituteInPlace $out/lib/config.js --replace-fail \
            "variant: typeof raw.variant === 'string' ? raw.variant : 'auto'," \
            "variant: typeof raw.variant === 'string' ? raw.variant : 'font'," \
            --replace-fail 'followAppearance: raw.follow_appearance !== false,' \
            'followAppearance: false,'

          makeWrapper ${pkgs.nodejs}/bin/node $out/bin/radar-node \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                config.packages.herdr
                pkgs.fontconfig
                pkgs.coreutils
                pkgs.git
              ]
            }
          substituteInPlace $out/herdr-plugin.toml --replace-fail \
            '"node"' '"'$out'/bin/radar-node"'

          # Generate the sidebar from the pinned upstream implementation, not
          # a copied palette. No evaluation-time build or network access needed.
          mkdir -p $out/share/fonts/truetype
          cp dist/HerdrAgentIconsMax-Regular.ttf $out/share/fonts/truetype/
          HOME=$TMPDIR node -e \
            "process.stdout.write(require('$out/lib/managed-config').sidebarBlock('dark') + '\\n')" \
            > $out/share/sidebar.toml
          runHook postInstall
        '';
        meta = {
          description = "Agent lifecycle, activity ordering and vendor icons for Herdr";
          homepage = "https://github.com/hhdebb/herdr-radar";
          license = with pkgs.lib.licenses; [
            mit
            ofl
          ];
          platforms = pkgs.lib.platforms.linux;
        };
      };
    };

  flake.modules.homeManager.herdr-radar =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      packages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
      radar = packages.herdr-radar;
      baseConfig = pkgs.writeText "herdr-base.toml" config.xdg.configFile."herdr/config.toml".text;
    in
    {
      home.packages = [ radar ];
      fonts.fontconfig.enable = true;
      programs.kitty.extraConfig = ''
        symbol_map U+E1A0-U+E1BA,U+E1C0-U+E1C5 Herdr Agent Icons Max
      '';

      # Other plugins still compose text normally. Append Radar's generated
      # sidebar at build time so Home Manager can keep the result immutable.
      xdg.configFile."herdr/config.toml".source = lib.mkForce (
        pkgs.runCommand "herdr-config.toml" { } ''
          cp ${radar}/share/sidebar.toml sidebar.toml
          chmod u+w sidebar.toml
          ${lib.optionalString (builtins.elem packages.herdr-agent-usage config.home.packages) ''
            ${pkgs.python3.withPackages (p: [ p.tomlkit ])}/bin/python ${./_append_usage.py} sidebar.toml
          ''}
          cat ${baseConfig} sidebar.toml > $out
        ''
      );
      xdg.configFile."herdr/config.toml".text = ''
        [[keys.command]]
        key = "prefix+comma"
        type = "plugin_action"
        command = "hhdebb.herdr-radar.settings"

        [[keys.command]]
        key = "prefix+r"
        type = "plugin_action"
        command = "hhdebb.herdr-radar.view-flip"
      '';

      home.activation.herdr-radar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${packages.herdr}/bin/herdr plugin link ${radar} --enabled
      '';
    };
}
