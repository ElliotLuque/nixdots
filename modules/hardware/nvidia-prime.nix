{ ... }:
{
  flake.modules.nixos.nvidia-prime =
    { lib, ... }:
    {
      services.xserver.videoDrivers = lib.mkForce [
        "modesetting"
        "nvidia"
      ];

      hardware.nvidia.prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };

      hardware.nvidia.powerManagement.enable = lib.mkForce true;
      hardware.nvidia.powerManagement.finegrained = lib.mkForce true;
    };
}
