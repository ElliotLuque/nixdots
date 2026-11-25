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
    # Dual-boot with Windows: keep the motherboard RTC in local time so Windows
    # does not lose 1h (CET) / 2h (CEST) after booting Linux.
    time.hardwareClockInLocalTime = true;
    hardware.nvidia.open = true;
    # Prevent the MediaTek Wi-Fi driver from probing the Microsoft Xbox Wireless
    # Adapter (045e:02fe) on usb 1-3, which fails with -110 and can wedge it.
    boot.blacklistedKernelModules = [ "mt76x2u" ];
    # Keep USB autosuspend off for the Xbox Wireless Adapter so it doesn't wedge
    # across warm reboots.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02fe", ATTR{power/control}="on"
    '';
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
