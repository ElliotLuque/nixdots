{
  host ? "",
  lib,
  ...
}:
let
  baseSettings = {
    appearance = {
      transparency = {
        enabled = true;
        base = "0.6";
        layers = "0.2";
      };
    };
    general = {
      apps = {
        terminal = [ "kitty" ];
      };
    };
    background = {
      desktopClock = {
        enabled = true;
        position = "top-left";
        shadow = {
          enabled = true;
        };
      };
    };
    idle = {
      lockBeforeSleep = false;
      inhibitWhenAudio = false;
      timeouts = [ ];
    };
    bar = {
      status = {
        showBattery = true;
        showKbLayout = true;
        showWifi = false;
        showAudio = true;
        showLockStatus = false;
      };
      scrollActions = {
        workspaces = false;
        brightness = false;
        volume = true;
      };
      workspaces = {
        activeLabel = "";
        occupiedLabel = "";
        shown = 4;
      };
      tray = {
        background = true;
        compact = true;
        recolour = true;
      };
    };
    paths = {
      mediaGif = "";
      sessionGif = "";
      wallpaperDir = "~/dotfiles/nixdots/wallpaper/mocha/";
    };
  };

  hostSettings = {
    nixos-pc = {
      bar.status.showBattery = false;
    };

    nixos-laptop = {
      bar.status.showBattery = true;
    };
  };

  selectedHostSettings = hostSettings.${host} or { };
in
{
  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true; # if you prefer starting from your compositor
      target = "graphical-session.target";
      environment = [ ];
    };
    settings = lib.recursiveUpdate baseSettings selectedHostSettings;
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };
}
