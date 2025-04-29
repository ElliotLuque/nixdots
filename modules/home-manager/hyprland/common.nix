{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
      pkgs.hyprlandPlugins.hyprsplit
    ];

    settings = {
      exec-once = [
        "swww-daemon && swww img ~/dotfiles/nixdots/wallpaper/mocha/cottages-river.png"
        "hyprpanel"
      ];

      # exec = [
      #   "wallpaper_random ~/dotfiles/nixdots/wallpaper/mocha &"
      # ];

      env = [
        "XCURSOR_SIZE,22"
        "XCURSOR_THEME,Bibata-Original-Classic"
        "HYPRCURSOR_SIZE,22"
        "HYPRCURSOR_THEME,hypr_Bibata-Original-Classic"
      ];

      misc = {
        vrr = "0";
        disable_hyprland_logo = "true";
        font_family = "JetBrains Mono Nerd Font";
      };

      debug = {
        damage_tracking = "0";
      };

      cursor = {
        no_hardware_cursors = "true";
        enable_hyprcursor = "true";
      };

      plugin = {
        hyprsplit = {
          num_workspaces = 4;
          persisent_workspaces = true;
        };

        dynamic-cursors = {
          enabled = "true";
          mode = "tilt";
          tilt = {
            limit = "3500";
            function = "quadratic";
          };

          hyprcursor = {
            enabled = "true";
          };
        };
      };

      general = {
        gaps_in = "8";
        gaps_out = "10";

        border_size = "3";

        "col.active_border" = "rgb(cba6f7)";
        "col.inactive_border" = "rgba(313244aa)";

        resize_on_border = "false";
        allow_tearing = "false";

        layout = "dwindle";
      };

      decoration = {
        rounding = "10";

        active_opacity = "1.0";
        inactive_opacity = "0.95";

        shadow = {
          enabled = "true";
          range = "12";
          render_power = "2";
          color = "rgba(cba6f7bb)";
          color_inactive = "rgba(313244aa)";
        };

        blur = {
          enabled = "true";
          size = "6";
          passes = "3";
          vibrancy = "0.1696";
        };
      };

      animations = {
        # Default
        enabled = "yes, please :)";

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 70%"
          "windowsOut, 1, 1.49, linear, popin 70%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "workspaces, 1, 5, easeOutQuint, slide"
        ];
      };

      dwindle = {
        preserve_split = "true";
      };

      "$terminal" = "kitty";

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, S, exec, screenshot-area"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod SHIFT, L, exec, hyprlock"
        "$mod, R, exec, $menu"
        "$mod, J, togglesplit"
        "$mod, 1, split:workspace, 1"
        "$mod, 2, split:workspace, 2"
        "$mod, 3, split:workspace, 3"
        "$mod, 4, split:workspace, 4"

        "$mod SHIFT, 1, split:movetoworkspace, 1"
        "$mod SHIFT, 2, split:movetoworkspace, 2"
        "$mod SHIFT, 3, split:movetoworkspace, 3"
        "$mod SHIFT, 4, split:movetoworkspace, 4"

        "$mod CTRL, 1, split:movetoworkspacesilent, 1"
        "$mod CTRL, 2, split:movetoworkspacesilent, 2"
        "$mod CTRL, 3, split:movetoworkspacesilent, 3"
        "$mod CTRL, 4, split:movetoworkspacesilent, 4"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, swapwindow, d"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      layerrule = [
        "blur,rofi"
      ];

      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "opacity 0.85 override 0.7 override 0.85 override, class:kitty"
        "opacity 0.85 override 0.7 override 0.85 override, class:rofi"
      ];
    };
  };
}
