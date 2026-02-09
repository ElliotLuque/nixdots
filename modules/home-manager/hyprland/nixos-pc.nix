{
  config,
  pkgs,
  username,
  ...
}:
{
  config = {
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
  };
}
