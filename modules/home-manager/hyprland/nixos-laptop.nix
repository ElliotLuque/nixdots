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
          render = {
            explicit_sync = "2";
            explicit_sync_kms = "0";
          };

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

            sensitivity = "1.0";
          };

          "$mod" = "SUPER";
          "$menu" = "rofi -show drun";
        };
      };
    };
  };
}
