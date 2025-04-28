{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.dotnetCorePackages.dotnet_8.sdk
  ];

  DOTNET_ROOT = "${pkgs.dotnetCorePackages.dotnet_8.sdk}";
}
