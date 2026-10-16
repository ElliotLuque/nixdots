{ inputs, config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.nixosConfigurations.nixos-laptop = inputs.nixpkgs.lib.nixosSystem {
    modules = [ modules.nixos.host-nixos-laptop ];
  };

  flake.modules.nixos.host-nixos-laptop = {
    imports = with modules.nixos; [
      ./_hardware-configuration.nix
      workstation
      elliot-workstation
      boot-workstation
      power-laptop
      nvidia
      nvidia-prime
      localsend
      ssh-server
      mosh
      # Opt in to campus-wifi after provisioning /etc/nixdots/campus-wifi.env.
    ];
    networking.hostName = "nixos-laptop";
    system.stateVersion = "24.11";
    boot.kernelParams = [ "nvidia.NVreg_DynamicPowerManagement=0x02" ];
    hardware.nvidia = {
      open = false;
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:2:0:0";
      };
    };

    home-manager.users.elliot = {
      imports = [ modules.homeManager.proton-vpn ];
      wayland.windowManager.hyprland.settings = {
        env = [
          {
            _args = [
              "AQ_DRM_DEVICES"
              "/dev/dri/card0:/dev/dri/card1"
            ];
          }
        ];
        config = {
          input = {
            sensitivity = 0;
            touchpad.natural_scroll = true;
          };
          device = [
            {
              name = "type:touchpad";
              sensitivity = 0.5;
            }
            {
              name = "type:mouse";
              sensitivity = 0;
            }
          ];
          decoration = {
            active_opacity = 1;
            inactive_opacity = 1;
            blur.enabled = false;
            shadow.enabled = false;
          };
        };
      };
    };
  };
}
