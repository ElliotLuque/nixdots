{ ... }:
{
  flake.modules.homeManager.hyprlock =
    { config, ... }:
    let
      inherit (config.lib.stylix) colors;
    in
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          background = [
            {
              monitor = "";
              path = toString config.stylix.image;
              blur_passes = 3;
              blur_size = 6;
              vibrancy = 0.1696;
            }
          ];

          general = {
            no_fade_in = false;
            grace = 0;
            disable_loading_bar = true;
            hide_cursor = true;
          };

          input-field = [
            {
              monitor = "";
              size = "350,64";
              outline_thickness = 0;
              dots_size = 0.2;
              dots_spacing = 0.5;
              dots_center = true;
              inner_color = "rgba(${colors.base01}99)";
              font_color = "0xff${colors.base05}";
              fail_color = "rgba(${colors.base01}99)";
              check_color = "rgba(${colors.base0C}33)";
              capslock_color = "0xff${colors.base0A}";
              fade_on_empty = false;
              font_family = "JetBrainsMono Nerd Font Bold Italic";
              font_size = 16;
              placeholder_text = "type password...";
              hide_input = false;
              position = "0,-90";
              halign = "center";
              valign = "center";
            }
          ];

          label = [
            {
              monitor = "";
              text = "cmd[update:1000] date +%H:%M";
              color = "0xff${colors.base05}";
              font_size = 140;
              font_family = "JetBrainsMono Nerd Font Bold";
              position = "0,150";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = "cmd[update:1000] echo \"\$USER@\$(hostname)\"";
              color = "0xff${colors.base0C}";
              font_size = 24;
              font_family = "JetBrainsMono Nerd Font Bold";
              position = "0,-10";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
