{ ... }:
{
  # OpenRGB: controls the Ducky One 2 RGB / Shine 7 keyboard (USB 04d9:0348)
  # and other RGB devices. Installs udev rules, the `openrgb` GUI/CLI and an
  # SDK server so profiles can be applied without root.
  flake.modules.nixos.rgb =
    { pkgs, ... }:
    {
      services.hardware.openrgb = {
        enable = true;
        package = pkgs.openrgb-with-all-plugins;
      };
    };
}
