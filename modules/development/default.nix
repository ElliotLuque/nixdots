{ inputs, ... }:
{
  flake.modules.nixos.development = {
    virtualisation.docker.enable = true;
    programs.nix-ld.enable = true;
  };

  flake.modules.homeManager.development = { pkgs, ... }: {
    home.packages = with pkgs; [
      (inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default.extend (
        { pkgs, lib, ... }:
        {
          # Remove when nixpkgs corrects the 6.0.2 pnpm dependency hash.
          plugins.lsp.servers.ts_ls.package = lib.mkForce (
            pkgs.typescript-language-server.overrideAttrs (old: {
              pnpmDeps = old.pnpmDeps.overrideAttrs {
                outputHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
              };
            })
          );
        }
      ))
      cmake
      gcc
      gnumake
      maven
      gradle
      jetbrains.idea
      vscode
      k6
      nodejs_24
      pnpm
      godot
      jdk21
    ];
    home.sessionVariables = {
      EDITOR = "nvim";
      JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
      JDK_JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
    };
    xdg.configFile."JetBrains/IntelliJIdea2025.3/idea64.vmoptions" = {
      force = true;
      text = ''
        -Dawt.toolkit.name=WLToolkit
      '';
    };
  };
}
