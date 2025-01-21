{ pkgs, config, ... }:
{
  boot = {
    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nomodeset"
    ];
  };
  services.xserver.videoDrivers = [ "nvidia" ]; 
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;

    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  environment = {
    systemPackages = with pkgs; [
      egl-wayland
      nvidia-vaapi-driver
    ];
    
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };
  };
}

