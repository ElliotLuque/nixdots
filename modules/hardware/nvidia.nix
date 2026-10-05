{ ... }:
{
  flake.modules.nixos.nvidia =
    { pkgs, config, ... }:
    {
      boot = {
        kernelParams = [
          "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        ];
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };

      environment = {
        systemPackages = with pkgs; [
          egl-wayland
          nvidia-vaapi-driver
        ];

        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
      };
    };
}
