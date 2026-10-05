{ inputs, ... }:
{
  flake.modules.homeManager.caelestia = { config, ... }: {
    imports = [ inputs.caelestia-shell.homeManagerModules.default ];

    programs.caelestia = {
      enable = true;
      systemd = {
        enable = true;
        target = "graphical-session.target";
        environment = [ ];
      };
      cli = {
        enable = true;
        settings.theme.enableGtk = true;
      };
      settings = {
        general = {
          apps.terminal = [ "kitty" ];
          idle = {
            lockBeforeSleep = false;
            inhibitWhenAudio = false;
            timeouts = [
              {
                timeout = 600;
                idleAction = "lock";
                inhibitWhenAudio = false;
                inhibitWhenCharging = false;
                respectInhibitors = true;
              }
            ];
          };
        };
        services.maxVolume = 1.3;
        background.desktopClock = {
          enabled = true;
          position = "top-left";
          shadow.enabled = true;
        };
        bar = {
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
          statusIcons = [
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
              enabled = true;
            }
          ];
        };
        paths = {
          mediaGif = "";
          sessionGif = "";
          wallpaperDir = "${config.xdg.dataHome}/wallpapers";
        };
      };
    };
  };
}
