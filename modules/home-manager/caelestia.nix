{ ... }:
{
  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true; # if you prefer starting from your compositor
      target = "graphical-session.target";
      environment = [ ];
    };
    settings = {
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
        inhibitWhenAudio = true;
        timeouts = [
          {
            timeout = 900;
            idleAction = "lock";
          }
        ];
      };
      bar = {
        status = {
          showBattery = false;
          showKbLayout = true;
          showWifi = false;
          showAudio = true;
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
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };
}
