{ config, inputs, pkgs, host, ... }:
let
  hyprsplit = inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua;
  dynamicCursors = pkgs.hyprlandPlugins.hypr-dynamic-cursors;
  hostConfig =
    if host == "nixos-pc" then
      ''
        hl.monitor({ output = "HDMI-A-2", mode = "3840x2160@60", position = "0x0", scale = 1.5 })
        hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "2560x0", scale = 1.5 })

        hl.config({
          cursor = { default_monitor = "HDMI-A-1" },
          debug = { damage_tracking = 0 },
          input = { kb_layout = "es", kb_options = "caps:super", follow_mouse = 1, sensitivity = -1 },
          opengl = { nvidia_anti_flicker = 0 },
        })
      ''
    else
      ''
        hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

        hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")
        hl.config({
          debug = { damage_tracking = 0 },
          input = {
            kb_layout = "es",
            kb_options = "caps:super",
            follow_mouse = 1,
            sensitivity = 0,
            touchpad = { natural_scroll = true },
          },
          device = {
            { name = "type:touchpad", sensitivity = 0.5 },
            { name = "type:mouse", sensitivity = 0 },
          },
          decoration = {
            active_opacity = 1,
            inactive_opacity = 1,
            blur = { enabled = false },
            shadow = { enabled = false },
          },
        })
      '';
in
{
  # Home Manager's settings serializer does not yet produce valid Lua for all
  # Hyprland keywords, so manage the native Lua configuration directly.
  wayland.windowManager.hyprland.enable = false;

  xdg.configFile = {
    "systemd/user/hyprland-session.target".text = ''
      [Unit]
      Description=Hyprland compositor session
      Wants=graphical-session.target
      Before=graphical-session.target
    '';
    "hypr/hyprsplit/init.lua".source = "${hyprsplit}/share/hyprsplit/init.lua";
    "hypr/hyprsplit-config.lua".text = ''
      local hs = require("hyprsplit")

      hs.config({ num_workspaces = 4, persistent_workspaces = true })

      local function move_to_workspace(workspace, follow)
        return function()
          local target = hs.get_workspace_string(tostring(workspace))
          hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))

          if follow then
            hl.dispatch(hl.dsp.focus({ workspace = target, on_current_monitor = true }))
          end
        end
      end

      for i = 1, 4 do
        hl.bind("SUPER + " .. i, hs.dsp.focus({ workspace = i }))
        hl.bind("SUPER + SHIFT + " .. i, move_to_workspace(i, true))
        hl.bind("SUPER + CTRL + " .. i, move_to_workspace(i, false))
      end

      hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
      hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
      hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
      hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
    '';
    "hypr/hyprland.lua".text = ''
      -- Generated from the Nix configuration. This is a native Hyprland Lua config.
      local config_home = os.getenv("XDG_CONFIG_HOME") or "${config.home.homeDirectory}/.config"
      package.path = config_home .. "/hypr/?.lua;" .. config_home .. "/hypr/?/init.lua;" .. package.path

      hl.plugin.load("${dynamicCursors}/lib/libhypr-dynamic-cursors.so")
      require("hyprsplit-config")

      hl.env("XCURSOR_SIZE", "22")
      hl.env("XCURSOR_THEME", "Bibata-Original-Classic")
      hl.env("HYPRCURSOR_SIZE", "22")
      hl.env("HYPRCURSOR_THEME", "hypr_Bibata-Original-Classic")
      hl.env("JDK_JAVA_OPTIONS", "-Dawt.toolkit.name=WLToolkit")

      ${hostConfig}

      hl.config({
        cursor = { no_hardware_cursors = true, enable_hyprcursor = true },
        debug = { disable_logs = false },
        misc = { disable_hyprland_logo = true, font_family = "JetBrains Mono Nerd Font" },
        general = {
          gaps_in = 6,
          gaps_out = 10,
          border_size = 3,
          col = { active_border = "rgb(cba6f7)", inactive_border = "rgba(313244aa)" },
          resize_on_border = false,
          allow_tearing = false,
          layout = "dwindle",
        },
        decoration = {
          rounding = 10,
          active_opacity = 1,
          inactive_opacity = 0.95,
          shadow = { enabled = true, range = 12, render_power = 2, color = "rgba(cba6f7bb)", color_inactive = "rgba(313244aa)" },
          blur = { enabled = true, size = 6, passes = 3, vibrancy = 0.1696 },
        },
        dwindle = { preserve_split = true },
      })

      hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
      hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
      hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
      hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
      hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
      hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })

      hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
      hl.bind("SUPER + Q", hl.dsp.window.close())
      hl.bind("SUPER + S", hl.dsp.exec_cmd("screenshot-area"))
      hl.bind("SUPER + R", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"))
      hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
      hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
      hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --set-limit 140 -i 5"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --set-limit 140 -d 5"), { locked = true, repeating = true })
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness-step up"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness-step down"), { locked = true, repeating = true })

      hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
      hl.window_rule({ name = "kitty-opacity", match = { class = "kitty" }, opacity = "0.85 override 0.7 override 0.85 override" })

      hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprland-session.target")
        hl.exec_cmd("protonvpn-app")
      end)
    '';
  };
}
