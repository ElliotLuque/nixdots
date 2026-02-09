{
  lib,
  pkgs,
  config,
  ...
}:
let
  font = "${config.stylix.fonts.monospace.name}";
  font-size = "${toString config.stylix.fonts.sizes.desktop}";

  workspace-active = "#${config.lib.stylix.colors.base07}";
  workspace-occupied = "#${config.lib.stylix.colors.base07}";
  workspace-available = "#${config.lib.stylix.colors.base04}";

  background = "#${config.lib.stylix.colors.base02}";
  accent = "#${config.lib.stylix.colors.base0E}";

  shutdown-color = "#${config.lib.stylix.colors.base08}";
  restart-color = "#${config.lib.stylix.colors.base0B}";
  logout-color = "#${config.lib.stylix.colors.base09}";
  sleep-color = "#${config.lib.stylix.colors.base0D}";
  dashboard-color = "#${config.lib.stylix.colors.base0D}";
  volume-color = "#${config.lib.stylix.colors.base0B}";
  network-color = "#${config.lib.stylix.colors.base0D}";
  bluetooth-color = "#${config.lib.stylix.colors.base0C}";
  clock-color = "#${config.lib.stylix.colors.base0E}";
  notifications-color = "#${config.lib.stylix.colors.base0A}";

  notification-title-color = "#${config.lib.stylix.colors.base0D}";

  cpu-color = "#${config.lib.stylix.colors.base08}";
  ram-color = "#${config.lib.stylix.colors.base09}";
  gpu-color = "#${config.lib.stylix.colors.base0B}";
  disk-color = "#${config.lib.stylix.colors.base0D}";

  directory1-color = "#${config.lib.stylix.colors.base08}";
  directory2-color = "#${config.lib.stylix.colors.base09}";
  directory3-color = "#${config.lib.stylix.colors.base0A}";
  directory4-color = "#${config.lib.stylix.colors.base0B}";
  directory5-color = "#${config.lib.stylix.colors.base0C}";
  directory6-color = "#${config.lib.stylix.colors.base0D}";
in
{
  programs.hyprpanel = {
    enable = false;

    settings = {
      scalingPriority = "both";

      notifications = {
        active_monitor = false;
        monitor = 1;
        clearDelay = 250;
      };

      theme = {
        bar = {
          menus = {
            menu = {
              dashboard = {
                profile = {
                  name = lib.mkForce "${accent}";
                  radius = "999px";
                };

                powermenu = {
                  shutdown = lib.mkForce "${shutdown-color}";
                  restart = lib.mkForce "${restart-color}";
                  logout = lib.mkForce "${logout-color}";
                  sleep = lib.mkForce "${sleep-color}";
                };

                controls = {
                  wifi.background = lib.mkForce "${network-color}";
                  bluetooth.background = lib.mkForce "${bluetooth-color}";
                  notifications.background = lib.mkForce "${notifications-color}";
                  volume.background = lib.mkForce "${volume-color}";
                  input.background = lib.mkForce "${accent}";
                };

                directories = {
                  left = {
                    middle.color = lib.mkForce "${directory1-color}";
                    top.color = lib.mkForce "${directory2-color}";
                    bottom.color = lib.mkForce "${directory3-color}";
                  };

                  right = {
                    middle.color = lib.mkForce "${directory4-color}";
                    top.color = lib.mkForce "${directory5-color}";
                    bottom.color = lib.mkForce "${directory6-color}";
                  };
                };

                monitors = {
                  cpu = {
                    icon = lib.mkForce "${cpu-color}";
                    bar = lib.mkForce "${cpu-color}";
                    label = lib.mkForce "${cpu-color}";
                  };
                  ram = {
                    icon = lib.mkForce "${ram-color}";
                    bar = lib.mkForce "${ram-color}";
                    label = lib.mkForce "${ram-color}";
                  };
                  gpu = {
                    icon = lib.mkForce "${gpu-color}";
                    bar = lib.mkForce "${gpu-color}";
                    label = lib.mkForce "${gpu-color}";
                  };
                  disk = {
                    icon = lib.mkForce "${disk-color}";
                    bar = lib.mkForce "${disk-color}";
                    label = lib.mkForce "${disk-color}";
                  };
                };
              };

              notifications = {
                label = lib.mkForce "${notifications-color}";
                switch.enabled = lib.mkForce "${notifications-color}";
                scrollbar.color = lib.mkForce "${notifications-color}";
                pager.button = lib.mkForce "${notifications-color}";
              };

              volume = {
                label.color = lib.mkForce "${volume-color}";
                listitems.active = lib.mkForce "${volume-color}";
                icons.active = lib.mkForce "${volume-color}";
                iconbutton.active = lib.mkForce "${volume-color}";
                audio_slider.primary = lib.mkForce "${volume-color}";
                input_slider.primary = lib.mkForce "${volume-color}";
              };

              bluetooth = {
                label.color = lib.mkForce "${bluetooth-color}";
                listitems.active = lib.mkForce "${bluetooth-color}";
                icons.active = lib.mkForce "${bluetooth-color}";
                iconbutton.active = lib.mkForce "${bluetooth-color}";
                scroller.color = lib.mkForce "${bluetooth-color}";
                switch.enabled = lib.mkForce "${bluetooth-color}";
              };

              network = {
                label.color = lib.mkForce "${network-color}";
                listitems.active = lib.mkForce "${network-color}";
                icons.active = lib.mkForce "${network-color}";
                iconbuttons.active = lib.mkForce "${network-color}";
                scroller.primary = lib.mkForce "${network-color}";
                switch.enabled = lib.mkForce "${network-color}";
              };

              clock = {
                time.time = lib.mkForce "${clock-color}";
                calendar = {
                  weekdays = lib.mkForce "${clock-color}";
                  paginator = lib.mkForce "${clock-color}";
                  currentday = lib.mkForce "${clock-color}";
                };
              };

              power = {
                buttons = {
                  shutdown = {
                    icon_background = lib.mkForce "${shutdown-color}";
                    text = lib.mkForce "${shutdown-color}";
                  };

                  restart = {
                    icon_background = lib.mkForce "${restart-color}";
                    text = lib.mkForce "${restart-color}";
                  };

                  logout = {
                    icon_background = lib.mkForce "${logout-color}";
                    text = lib.mkForce "${logout-color}";
                  };

                  sleep = {
                    icon_background = lib.mkForce "${sleep-color}";
                    text = lib.mkForce "${sleep-color}";
                  };
                };
              };
            };
          };

          border = {
            location = "bottom";
            color = lib.mkForce "${accent}";
            width = "0.1em";
            enableShadow = true;
          };

          buttons = {
            style = "split";
            background_hover_opacity = 75;

            notifications.icon = lib.mkForce "${notifications-color}";
            dashboard.icon = lib.mkForce "${dashboard-color}";

            workspaces = {
              pill = {
                width = "4em";
                active_width = "18em";
                height = "3.5em";
              };

              hover = lib.mkForce "${accent}";
              active = lib.mkForce "${workspace-active}";
              occupied = lib.mkForce "${workspace-occupied}";
              available = lib.mkForce "${workspace-available}";
            };

            volume = {
              text = lib.mkForce "${volume-color}";
              icon = lib.mkForce "${background}";
              icon_background = lib.mkForce "${volume-color}";
            };

            bluetooth = {
              text = lib.mkForce "${bluetooth-color}";
              icon = lib.mkForce "${background}";
              icon_background = lib.mkForce "${bluetooth-color}";
            };

            network = {
              text = lib.mkForce "${network-color}";
              icon = lib.mkForce "${background}";
              icon_background = lib.mkForce "${network-color}";
            };

            clock = {
              text = lib.mkForce "${clock-color}";
              icon = lib.mkForce "${background}";
              icon_background = lib.mkForce "${clock-color}";
            };
          };

          shadow = "0px 1px 2px 1px ${accent}";
          opacity = 85;
          outer_spacing = "0.4em";

        };

        notification.label = lib.mkForce "${notification-title-color}";

        font = {
          name = "${font}";
          size = "${font-size}px";
          weight = 600;
        };
      };

      layout = {
        bar.layouts = {
          "*" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [
              "media"
            ];
            right = [
              "volume"
              "bluetooth"
              "network"
              "clock"
              "systray"
              "notifications"
              "power"
            ];
          };
        };
      };
      bar = {
        launcher = {
          autoDetectIcon = true;
        };
        clock = {
          format = "%a %d %b %H:%M";
        };
      };
      menus = {
        clock = {
          time = {
            military = true;
          };
          weather.enabled = false;
        };

        dashboard = {
          powermenu.avatar.image = "/home/elliot/dotfiles/nixdots/modules/home-manager/hyprpanel/profile.png";
          stats.enable_gpu = true;

          shortcuts = {
            left = {
              shortcut1 = {
                command = "google-chrome-stable";
                tooltip = "Google Chrome";
                icon = "";
              };
              shortcut2 = {
                command = "spotify";
              };
            };

            right = {
              shortcut1 = {
                command = "color-picker";
              };
              shortcut3 = {
                command = "screenshot-area";
              };
            };
          };
        };
      };
    };

    # override = {
    #   "theme.bar.menus.menu.dashboard.profile.radius" = "999px";
    #   "theme.bar.border.location" = "bottom";
    #   "theme.bar.border.color" = "${accent}";
    #   "theme.bar.opacity" = 85;
    #   "theme.bar.border.width" = "0.1em";
    #   "theme.bar.border.enableShadow" = true;
    #   "theme.bar.shadow" = "0px 1px 2px 1px ${accent}";
    #   "theme.bar.outer_spacing" = "0.4em";
    #   "theme.bar.buttons.style" = "split";
    #   "theme.bar.buttons.background_hover_opacity" = 75;
    #
    #   "theme.bar.buttons.notifications.icon" = "${notifications-color}";
    #   "theme.bar.buttons.dashboard.icon" = "${dashboard-color}";
    #
    #   "theme.bar.buttons.workspaces.pill.width" = "4em";
    #   "theme.bar.buttons.workspaces.pill.active_width" = "18em";
    #   "theme.bar.buttons.workspaces.pill.height" = "3.5em";
    #   "theme.bar.buttons.workspaces.hover" = "${accent}";
    #   "theme.bar.buttons.workspaces.active" = "${workspace-active}";
    #   "theme.bar.buttons.workspaces.occupied" = "${workspace-occupied}";
    #   "theme.bar.buttons.workspaces.available" = "${workspace-available}";
    #
    #   "theme.bar.buttons.volume.text" = "${volume-color}";
    #   "theme.bar.buttons.volume.icon" = "${background}";
    #   "theme.bar.buttons.volume.icon_background" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.label.color" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.listitems.active" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.icons.active" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.iconbutton.active" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.audio_slider.primary" = "${volume-color}";
    #   "theme.bar.menus.menu.volume.input_slider.primary" = "${volume-color}";
    #
    #   "theme.bar.buttons.bluetooth.text" = "${bluetooth-color}";
    #   "theme.bar.buttons.bluetooth.icon" = "${background}";
    #   "theme.bar.buttons.bluetooth.icon_background" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.label.color" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.listitems.active" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.icons.active" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.iconbutton.active" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.scroller.color" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.bluetooth.switch.enabled" = "${bluetooth-color}";
    #
    #   "theme.bar.buttons.network.text" = "${network-color}";
    #   "theme.bar.buttons.network.icon" = "${background}";
    #   "theme.bar.buttons.network.icon_background" = "${network-color}";
    #   "theme.bar.menus.menu.network.label.color" = "${network-color}";
    #   "theme.bar.menus.menu.network.listitems.active" = "${network-color}";
    #   "theme.bar.menus.menu.network.icons.active" = "${network-color}";
    #   "theme.bar.menus.menu.network.iconbuttons.active" = "${network-color}";
    #   "theme.bar.menus.menu.network.scroller.color" = "${network-color}";
    #   "theme.bar.menus.menu.network.switch.enabled" = "${network-color}";
    #
    #   "theme.bar.buttons.clock.text" = "${clock-color}";
    #   "theme.bar.buttons.clock.icon" = "${background}";
    #   "theme.bar.buttons.clock.icon_background" = "${clock-color}";
    #
    #   "theme.bar.menus.menu.clock.time.time" = "${clock-color}";
    #   "theme.bar.menus.menu.clock.calendar.weekdays" = "${clock-color}";
    #   "theme.bar.menus.menu.clock.calendar.paginator" = "${clock-color}";
    #   "theme.bar.menus.menu.clock.calendar.currentday" = "${clock-color}";
    #
    #   "theme.notification.label" = "${notification-title-color}";
    #
    #   "notifications.active_monitor" = false;
    #   "notifications.monitor" = 1;
    #   "notifications.clearDelay" = 200;
    #   "theme.bar.menus.menu.notifications.label" = "${notifications-color}";
    #   "theme.bar.menus.menu.notifications.switch.enabled" = "${notifications-color}";
    #   "theme.bar.menus.menu.notifications.scrollbar.color" = "${notifications-color}";
    #   "theme.bar.menus.menu.notifications.pager.button" = "${notifications-color}";
    #
    #   "theme.bar.menus.menu.power.buttons.shutdown.icon_background" = "${shutdown-color}";
    #   "theme.bar.menus.menu.power.buttons.shutdown.text" = "${shutdown-color}";
    #   "theme.bar.menus.menu.power.buttons.restart.icon_background" = "${restart-color}";
    #   "theme.bar.menus.menu.power.buttons.restart.text" = "${restart-color}";
    #   "theme.bar.menus.menu.power.buttons.logout.icon_background" = "${logout-color}";
    #   "theme.bar.menus.menu.power.buttons.logout.text" = "${logout-color}";
    #   "theme.bar.menus.menu.power.buttons.sleep.icon_background" = "${sleep-color}";
    #   "theme.bar.menus.menu.power.buttons.sleep.text" = "${sleep-color}";
    #
    #   "theme.bar.menus.menu.dashboard.powermenu.shutdown" = "${shutdown-color}";
    #   "theme.bar.menus.menu.dashboard.powermenu.restart" = "${restart-color}";
    #   "theme.bar.menus.menu.dashboard.powermenu.logout" = "${logout-color}";
    #   "theme.bar.menus.menu.dashboard.powermenu.sleep" = "${sleep-color}";
    #
    #   "theme.bar.menus.menu.dashboard.profile.name" = "${accent}";
    #
    #   "theme.bar.menus.menu.dashboard.controls.wifi.background" = "${network-color}";
    #   "theme.bar.menus.menu.dashboard.controls.bluetooth.background" = "${bluetooth-color}";
    #   "theme.bar.menus.menu.dashboard.controls.notifications.background" = "${notifications-color}";
    #   "theme.bar.menus.menu.dashboard.controls.volume.background" = "${volume-color}";
    #   "theme.bar.menus.menu.dashboard.controls.input.background" = "${accent}";
    #
    #   "theme.bar.menus.menu.dashboard.directories.left.top.color" = "${directory1-color}";
    #   "theme.bar.menus.menu.dashboard.directories.left.middle.color" = "${directory2-color}";
    #   "theme.bar.menus.menu.dashboard.directories.left.bottom.color" = "${directory3-color}";
    #   "theme.bar.menus.menu.dashboard.directories.right.middle.color" = "${directory4-color}";
    #   "theme.bar.menus.menu.dashboard.directories.right.top.color" = "${directory5-color}";
    #   "theme.bar.menus.menu.dashboard.directories.right.bottom.color" = "${directory6-color}";
    #
    #   "theme.bar.menus.menu.dashboard.monitors.cpu.icon" = "${cpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.cpu.bar" = "${cpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.cpu.label" = "${cpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.ram.icon" = "${ram-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.ram.bar" = "${ram-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.ram.label" = "${ram-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.gpu.icon" = "${gpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.gpu.bar" = "${gpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.gpu.label" = "${gpu-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.disk.icon" = "${disk-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.disk.bar" = "${disk-color}";
    #   "theme.bar.menus.menu.dashboard.monitors.disk.label" = "${disk-color}";
    # };
  };
}
