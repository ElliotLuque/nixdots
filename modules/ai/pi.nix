{ inputs, ... }:
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      home.file.".pi/agent/themes/catppuccin-mocha.json".source = ./catppuccin-mocha.json;
    };
}
