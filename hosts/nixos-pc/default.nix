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
      ollama-cuda
      localsend
      ssh-server
      mosh
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
      xdg.configFile."hypr/host.lua".text = ''
        hl.monitor({ output = "HDMI-A-2", mode = "3840x2160@60", position = "0x0", scale = 1.5 })
        hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "2560x0", scale = 1.5 })
        hl.config({
          cursor = { default_monitor = "HDMI-A-1" },
          debug = { damage_tracking = 0 },
          input = { kb_layout = "es", kb_options = "caps:super", follow_mouse = 1, sensitivity = -1 },
          opengl = { nvidia_anti_flicker = 0 },
        })
      '';
      programs.caelestia.settings = {
        appearance.transparency = {
          enabled = true;
          base = 0.6;
          layers = 0.2;
        };
        bar.statusIcons = lib.mkForce [
          {
            id = "lockStatus";
            enabled = false;
          }
          {
            id = "audio";
            enabled = true;
          }
          {
            id = "microphone";
            enabled = false;
          }
          {
            id = "kbLayout";
            enabled = false;
          }
          {
            id = "network";
            enabled = false;
          }
          {
            id = "bluetooth";
            enabled = true;
          }
          {
            id = "battery";
            enabled = false;
          }
        ];
      };
    };
  };
}
