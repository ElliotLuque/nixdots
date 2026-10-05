{ inputs, config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    imports = [ config.flake.modules.nixos.theme ];
    environment.systemPackages = [ pkgs.wl-clipboard ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Enable = "Source,Sink,Media,Socket";
    };
    services.blueman.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."10-bluetooth-codecs" = {
        "bluez5.enable-msbc" = true;
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-aptx" = true;
        "bluez5.enable-aptx-hd" = true;
        "bluez5.enable-ldac" = true;
      };
    };
    programs = {
      fuse.enable = true;
      dconf.enable = true;
      appimage = {
        enable = true;
        binfmt = true;
      };
      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };
    };
    services.dbus.enable = true;
    services.greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.greetd}/bin/agreety --cmd 'start-hyprland'";
    };
  };

  flake.modules.homeManager.desktop = {
    imports = with config.flake.modules.homeManager; [
      theme
      hyprland
      hyprlock
      hyprpaper
      caelestia
      desktop-scripts
      desktop-xdg
      desktop-apps
      media
    ];
    programs.kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font Propo";
        size = 14;
      };
      settings = {
        copy_on_select = "clipboard";
        cursor_trail = "1";
        disable_ligatures = "always";
      };
      shellIntegration.enableFishIntegration = true;
    };
  };
}
