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
            debug = {
              damage_tracking = "0";
            };

            monitor = [
              ", preferred, auto, 1"
            ];

            env = [
              "AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
            ];

            input = {
              kb_layout = "es";
              kb_options = "caps:super";

              follow_mouse = "1";

              sensitivity = "0.5";
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
