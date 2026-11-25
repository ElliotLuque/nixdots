{ inputs, ... }:
{
  flake.modules.nixos.development = {
    virtualisation.docker.enable = true;
    programs.nix-ld.enable = true;
  };

  flake.modules.homeManager.development = { pkgs, ... }: {
    home.packages = with pkgs; [
      inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
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
