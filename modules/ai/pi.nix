{ inputs, ... }:
{
  flake.modules.homeManager.pi =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
