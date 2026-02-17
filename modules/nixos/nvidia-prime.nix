{ lib, ... }:
{
  services.xserver.videoDrivers = lib.mkForce [
    "modesetting"
    "nvidia"
  ];

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:2:0:0";

    sync.enable = lib.mkForce false;
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };

  hardware.nvidia.powerManagement.finegrained = lib.mkForce true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkForce "iHD";
    __GLX_VENDOR_LIBRARY_NAME = lib.mkForce "mesa";
  };
}
