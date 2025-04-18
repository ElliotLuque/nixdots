{ pkgs, config, ... }:
let
  font = "${config.stylix.fonts.monospace.name}";
  font-size = "${toString config.stylix.fonts.sizes.desktop}";

  workspace-active = "#${config.lib.stylix.colors.base05}";
  workspace-occupied = "#${config.lib.stylix.colors.base02}";

  background = "#${config.lib.stylix.colors.base02}";

  dashboard-color = "#${config.lib.stylix.colors.base0D}";
  volume-color = "#${config.lib.stylix.colors.base0B}";
  network-color = "#${config.lib.stylix.colors.base0D}";
  bluetooth-color = "#${config.lib.stylix.colors.base0C}";
  clock-color = "#${config.lib.stylix.colors.base0E}";
  notifications-color = "#${config.lib.stylix.colors.base0F}";
in
{
  programs.hyprpanel = {
    enable = true;

    settings = {
      scalingPriority = "both";

      theme = {
        font = {
          name = "${font}";
          size = "${font-size}px";
          weight = 600;
        };
      };

      layout = {
        "bar.layouts" = {
          "*" = {
            "left" = [
              "dashboard"
              "workspaces"
            ];
            "middle" = [
              "media"
            ];
            "right" = [
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
      menus.clock = {
        time = {
          military = true;
        };
        weather.enabled = false;
      };
    };

    override = {
      "theme.bar.outer_spacing" = "0.4em";
      "theme.bar.buttons.style" = "split";
      "theme.bar.buttons.background_hover_opacity" = 85;

      "theme.bar.buttons.notifications.icon" = "${notifications-color}";
      "theme.bar.buttons.dashboard.icon" = "${dashboard-color}";

      "theme.bar.buttons.workspaces.active" = "${workspace-active}";
      "theme.bar.buttons.workspaces.occupied" = "${workspace-occupied}";

      "theme.bar.buttons.volume.text" = "${volume-color}";
      "theme.bar.buttons.volume.icon" = "${background}";
      "theme.bar.buttons.volume.icon_background" = "${volume-color}";

      "theme.bar.buttons.bluetooth.text" = "${bluetooth-color}";
      "theme.bar.buttons.bluetooth.icon" = "${background}";
      "theme.bar.buttons.bluetooth.icon_background" = "${bluetooth-color}";

      "theme.bar.buttons.network.text" = "${network-color}";
      "theme.bar.buttons.network.icon" = "${background}";
      "theme.bar.buttons.network.icon_background" = "${network-color}";

      "theme.bar.buttons.clock.text" = "${clock-color}";
      "theme.bar.buttons.clock.icon" = "${background}";
      "theme.bar.buttons.clock.icon_background" = "${clock-color}";

      "theme.bar.menus.menu.clock.time.time" = "${clock-color}";
      "theme.bar.menus.menu.clock.calendar.weekdays" = "${clock-color}";
      "theme.bar.menus.menu.clock.calendar.paginator" = "${clock-color}";
      "theme.bar.menus.menu.clock.calendar.currentday" = "${clock-color}";
    };
  };
}
