{
  config,
  lib,
  pkgs,
  username,
  hyprlandLowPerformance ? false,
  ...
}:
{
  config = lib.mkMerge [
    {
      home-manager.users.${username} = {
        wayland.windowManager.hyprland = {
          enable = true;

          settings = {
            opengl = {
              nvidia_anti_flicker = "0";
            };

            debug = {
              damage_tracking = "0";
            };

            cursor = {
              default_monitor = "HDMI-A-2";
            };

            monitor = [
              "HDMI-A-2,3840x2160@60,0x0,1.5"
              "HDMI-A-1,3840x2160@60,2560x0,1.5"
            ];

            input = {
              kb_layout = "es";
              kb_options = "caps:super";

              follow_mouse = "1";

              sensitivity = "-1.0";
            };

            "$mod" = "SUPER";
            "$menu" = "caelestia shell drawers toggle launcher";
          };
        };
      };
    }
    (lib.mkIf hyprlandLowPerformance {
      home-manager.users.${username}.wayland.windowManager.hyprland.settings = {
        # animations.enabled = lib.mkForce "no";

        decoration = {
          active_opacity = lib.mkForce "1.0";
          inactive_opacity = lib.mkForce "1.0";
          blur.enabled = lib.mkForce "false";
          shadow.enabled = lib.mkForce "false";
        };

        layerrule = lib.mkForce [ ];

        windowrule = lib.mkForce [
          "suppress_event maximize, match:class .*"
        ];
      };
    })
  ];
}
