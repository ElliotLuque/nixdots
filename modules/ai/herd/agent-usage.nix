{ inputs, config, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.herdr-agent-usage = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-agent-usage";
        version = "1.6.2";
        src = inputs.herdr-agent-usage;
        cargoHash = "sha256-v3C+ajqgYzkeyWQLHFv0xZlOC5RL3awc5XDWIBpLDzE=";
        nativeBuildInputs = [ pkgs.makeWrapper ];
        patches = [ ./_usage-radar-order.patch ];
        # Upstream configure_round_trip tests assume ownership of Herdr/font
        # files. Run the library suite and our declarative integration check.
        cargoTestFlags = [ "--lib" ];
        postPatch = ''
          # Nix/Radar own the sidebar, font and agent order. Keep upstream's
          # credential-scoped collectors and reversible agent hook installer.
          substituteInPlace src/configure/mod.rs --replace-fail \
            'herdr::apply(agents, layout, gap, fields, brand)?;' \
            'println!("Sidebar managed by Nix/Radar.");' \
            --replace-fail 'for note in font::install(cache.root())? {' \
            'for note in Vec::<String>::new() {' \
            --replace-fail 'herdr::uninstall(agents, full, fields, brand)?;' \
            'println!("Sidebar managed by Nix/Radar.");' \
            --replace-fail 'font::uninstall(cache.root())?;' \
            'println!("Font managed by Nix/Radar.");'
        '';
        installPhase = ''
          runHook preInstall
          install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/herdr-agent-quota \
            $out/bin/herdr-agent-quota
          runHook postInstall
        '';
        postInstall = ''
          wrapProgram $out/bin/herdr-agent-quota \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                config.packages.herdr
                pkgs.bash
                pkgs.coreutils
              ]
            }
          # Preserve the layout expected by actions and hook discovery.
          mkdir -p $out/target/release
          ln -s ../../bin/herdr-agent-quota $out/target/release/herdr-agent-quota
          # v1.6.2 still uses the old upstream binary/plugin name.
          ln -s herdr-agent-quota $out/bin/herdr-agent-usage
          cp herdr-plugin.toml $out/
          substituteInPlace $out/herdr-plugin.toml --replace-fail \
            'command = ["cargo", "build", "--release"]' \
            'command = ["${pkgs.coreutils}/bin/true"]' \
            --replace-fail '["sh", "-c",' '["${pkgs.bash}/bin/sh", "-c",' \
            --replace-fail 'configure --apply &&' \
            'configure --apply --agent claude,codex,opencode,pi --sidebar-layout stacked &&'
        '';
        meta = {
          description = "Credential-scoped agent context and subscription usage for Herdr";
          homepage = "https://github.com/levi-qiao/herdr-agent-usage";
          license = pkgs.lib.licenses.mit;
          mainProgram = "herdr-agent-usage";
          platforms = pkgs.lib.platforms.linux;
        };
      };
    };

  flake.modules.homeManager.herdr-agent-usage =
    { pkgs, lib, ... }:
    let
      packages = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
      usage = packages.herdr-agent-usage;
    in
    {
      imports = [ config.flake.modules.homeManager.herdr-radar ];
      home.packages = [ usage ];
      xdg.configFile."herdr/config.toml".text = ''
        [[keys.command]]
        key = "prefix+shift+q"
        type = "plugin_action"
        command = "herdr-agent-quota.open-settings"

        [[keys.command]]
        key = "prefix+shift+r"
        type = "plugin_action"
        command = "herdr-agent-quota.refresh"
      '';
      home.activation.herdr-agent-usage = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${packages.herdr}/bin/herdr plugin link ${usage} --enabled
        # The patched installer manages mutable agent hooks/cache only. Wait
        # until the new declarative Herdr config has been linked before reload.
        run ${packages.herdr}/bin/herdr plugin action invoke herdr-agent-quota.configure
      '';
    };
}
