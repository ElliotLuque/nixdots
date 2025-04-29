{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.dotnetCorePackages.dotnet_8.sdk
    omnisharp-roslyn
  ];

  DOTNET_ROOT = "${pkgs.dotnetCorePackages.dotnet_8.sdk}/bin";
}
