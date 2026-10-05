{ inputs, ... }:
{
  flake.modules.homeManager.herdr-projects =
    { pkgs, lib, ... }:
    let
      herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      version = "0.2.34";
      releases = {
        x86_64-linux = {
          target = "x86_64-unknown-linux-musl";
          sha256 = "f9b8093bcc7cf2f8df3780acc984bb371c9ef28abce87ac43fafb5852107b258";
        };
        aarch64-linux = {
          target = "aarch64-unknown-linux-musl";
          sha256 = "0aa18562ff1fe377b2b7bc4f339199d18efc75972c87f4a14eb8c15e9caa4cfc";
        };
      };
      release = releases.${pkgs.stdenv.hostPlatform.system};
      binary = pkgs.fetchurl {
        url = "https://github.com/eliasstravik/herdr-projects/releases/download/v${version}/herdr-projects-${release.target}";
        inherit (release) sha256;
      };
      plugin = pkgs.stdenvNoCC.mkDerivation {
        pname = "herdr-projects";
        inherit version;
        src = inputs.herdr-projects;
        dontBuild = true;
        dontStrip = true;
        installPhase = ''
          runHook preInstall
          # Actions and skill discovery rely on the upstream binary layout.
          mkdir -p $out/bin $out/target/release
          install -m755 ${binary} $out/target/release/herdr-projects
          ln -s ../target/release/herdr-projects $out/bin/herdr-projects
          cp herdr-plugin.toml $out/
          cp -R skill $out/
          # The binary is already installed; never download during activation.
          substituteInPlace $out/herdr-plugin.toml --replace-fail \
            'command = ["sh", "scripts/install.sh"]' \
            'command = ["${pkgs.coreutils}/bin/true"]'
          runHook postInstall
        '';

        meta = {
          description = "Projects, coordinator agents and parallel threads for Herdr";
          homepage = "https://github.com/eliasstravik/herdr-projects";
          license = lib.licenses.mit;
          mainProgram = "herdr-projects";
          platforms = builtins.attrNames releases;
        };
      };
    in
    {
      home.packages = [ plugin ];

      # Keep the popup binding declarative: upstream configure would try to
      # rewrite Home Manager's read-only Herdr config.
      xdg.configFile."herdr/config.toml".text = ''
        [[keys.command]]
        key = "prefix+a"
        type = "plugin_action"
        command = "herdr-projects.open-popup"
      '';

      # Share Herdr's mutable registry with other plugins without replacing it.
      home.activation.herdr-projects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${herdr}/bin/herdr plugin link ${plugin} --enabled
      '';
    };
}
