{ inputs, config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.nixosConfigurations.nixos-pc = inputs.nixpkgs.lib.nixosSystem {
    modules = [ modules.nixos.host-nixos-pc ];
  };

  flake.modules.nixos.host-nixos-pc = { lib, ... }: {
    imports = with modules.nixos; [
      ./_hardware-configuration.nix
      workstation
      elliot-workstation
      boot-workstation
      nvidia
      nvidia-desktop
      rgb
      ollama-cuda
      localsend
      ssh-server
      mosh
      campus-vpn
    ];
    networking.hostName = "nixos-pc";
    system.stateVersion = "24.11";
    hardware.nvidia.open = true;
    powerManagement.cpuFreqGovernor = "performance";
    services.ollama.loadModels = [ "qwen3.8:27b-q4_k_m" ];

    home-manager.users.elliot = {
      imports = [
        modules.homeManager.local-llm
        modules.homeManager.proton-vpn
      ];
      wayland.windowManager.hyprland.settings = {
        monitor = [
          {
            output = "HDMI-A-2";
            mode = "3840x2160@60";
            position = "0x0";
            scale = 1.5;
          }
          {
            output = "HDMI-A-1";
            mode = "3840x2160@60";
            position = "2560x0";
            scale = 1.5;
          }
        ];
        config = {
          cursor.default_monitor = "HDMI-A-1";
          input.sensitivity = -1;
          opengl.nvidia_anti_flicker = 0;
        };
      };
    };
  };
}
