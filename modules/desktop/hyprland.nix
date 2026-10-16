{ inputs, ... }:
{
  flake.modules.homeManager.hyprland =
    {
      pkgs,
      lib,
      ...
    }:
    let
      hyprsplit = inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplitlua;
      dynamicCursors =
        inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors;
      lua = lib.generators.mkLuaInline;
      bind = key: dispatcher: {
        _args = [
          key
          (lua dispatcher)
        ];
      };
      bindWith = key: dispatcher: flags: {
        _args = [
          key
          (lua dispatcher)
          flags
        ];
      };
      curve = name: points: {
        _args = [
          name
          {
            type = "bezier";
            inherit points;
          }
        ];
      };
      bibataHyprcursor = pkgs.stdenvNoCC.mkDerivation {
        pname = "bibata-original-classic-hyprcursor";
        version = "1.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "rtgiskard";
          repo = "bibata_cursor";
          rev = "f4ccfe8abb63fddc7b3ce51a866fd8378395cb3d";
          hash = "sha256-p36pHyoVOcDPm/tbk8YKsL+ItTaVKrGTfQ8zp022mGA=";
        };

        nativeBuildInputs = [ pkgs.python3 ];

        buildPhase = ''
          runHook preBuild
          python3 src/cursor_utils.py --hypr --theme Bibata-Original-Classic --out-dir out
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/icons
          cp -r out/Bibata-Original-Classic $out/share/icons/
          runHook postInstall
        '';
      };
    in
    {
      home.packages = [ bibataHyprcursor ];
      xdg.configFile."hypr/hyprsplit/init.lua".source = "${hyprsplit}/share/hyprsplit/init.lua";

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        # The NixOS module owns the compositor and portal packages.
        package = null;
        portalPackage = null;
        systemd.enable = true;
        plugins = [ dynamicCursors ];

        # Curves must be defined before animations reference them.
        importantPrefixes = [
          "env"
          "config"
          "curve"
        ];

        extraLuaFiles = {
          "hyprsplit-config" = ''
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
        };

        settings = {
          env = map (args: { _args = args; }) [
            [
              "XCURSOR_SIZE"
              "22"
            ]
            [
              "XCURSOR_THEME"
              "Bibata-Original-Classic"
            ]
            [
              "HYPRCURSOR_SIZE"
              "22"
            ]
            [
              "HYPRCURSOR_THEME"
              "Bibata-Original-Classic"
            ]
            [
              "JDK_JAVA_OPTIONS"
              "-Dawt.toolkit.name=WLToolkit"
            ]
          ];

          monitor = lib.mkDefault [
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];

          config = {
            cursor = {
              no_hardware_cursors = true;
              enable_hyprcursor = true;
            };
            debug.disable_logs = false;
            misc = {
              disable_hyprland_logo = true;
              font_family = "JetBrains Mono Nerd Font";
            };
            input = {
              kb_layout = lib.mkDefault "es";
              kb_options = lib.mkDefault "caps:super";
              follow_mouse = lib.mkDefault 1;
            };
            general = {
              gaps_in = 6;
              gaps_out = 10;
              border_size = 0;
              resize_on_border = false;
              allow_tearing = false;
              layout = "scrolling";
            };
            decoration = {
              rounding = 10;
              active_opacity = lib.mkDefault 1;
              inactive_opacity = lib.mkDefault 0.8;
              shadow.enabled = lib.mkDefault false;
              blur = {
                enabled = lib.mkDefault true;
                size = 6;
                passes = 3;
                vibrancy = 0.1696;
              };
            };
            plugin.dynamic_cursors = {
              enabled = true;
              mode = "tilt";
              tilt = {
                limit = 8000;
                activation = "quadratic";
                window = 100;
                full = 22;
              };
              shake = {
                enabled = true;
                threshold = 6.0;
                base = 4.0;
                speed = 4.0;
                limit = 6.0;
                timeout = 1200;
                effects = false;
              };
              hyprcursor = {
                enabled = true;
                nearest = 1;
                resolution = -1;
                fallback = "clientside";
              };
            };
          };

          curve = [
            (curve "easeOutQuint" [
              [
                0.23
                1
              ]
              [
                0.32
                1
              ]
            ])
            (curve "easeInOutCubic" [
              [
                0.65
                0.05
              ]
              [
                0.36
                1
              ]
            ])
            (curve "linear" [
              [
                0
                0
              ]
              [
                1
                1
              ]
            ])
            (curve "almostLinear" [
              [
                0.5
                0.5
              ]
              [
                0.75
                1
              ]
            ])
            (curve "quick" [
              [
                0.15
                0
              ]
              [
                0.1
                1
              ]
            ])
          ];
          animation = [
            {
              leaf = "border";
              enabled = true;
              speed = 5.39;
              bezier = "easeOutQuint";
            }
            {
              leaf = "windows";
              enabled = true;
              speed = 4.79;
              bezier = "easeOutQuint";
            }
            {
              leaf = "workspaces";
              enabled = true;
              speed = 5;
              bezier = "easeOutQuint";
              style = "slidevert";
            }
          ];

          bind = [
            (bind "SUPER + Return" ''hl.dsp.exec_cmd("kitty")'')
            (bind "SUPER + Q" "hl.dsp.window.close()")
            (bind "SUPER + S" ''hl.dsp.exec_cmd("screenshot-area")'')
            (bind "SUPER + R" ''hl.dsp.exec_cmd("caelestia shell drawers toggle launcher")'')
            (bind "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')
            (bind "SUPER + F" ''hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'')
            (bind "SUPER + SHIFT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'')
            (bind "SUPER + left" ''hl.dsp.focus({ direction = "left" })'')
            (bind "SUPER + right" ''hl.dsp.focus({ direction = "right" })'')
            (bind "SUPER + up" ''hl.dsp.focus({ direction = "up" })'')
            (bind "SUPER + down" ''hl.dsp.focus({ direction = "down" })'')
            (bindWith "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
            (bindWith "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
            (bindWith "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("pamixer --set-limit 140 -i 5")'' {
              locked = true;
              repeating = true;
            })
            (bindWith "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("pamixer --set-limit 140 -d 5")'' {
              locked = true;
              repeating = true;
            })
            (bindWith "XF86AudioMute" ''hl.dsp.exec_cmd("pamixer -t")'' { locked = true; })
            (bindWith "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightness-step up")'' {
              locked = true;
              repeating = true;
            })
            (bindWith "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightness-step down")'' {
              locked = true;
              repeating = true;
            })
          ];

          window_rule = [
            {
              name = "suppress-maximize";
              match.class = ".*";
              suppress_event = "maximize";
            }
            {
              name = "kitty-opacity";
              match.class = "kitty";
              opacity = "0.85 override 0.45 override 0.85 override";
            }
            {
              name = "paseo-opacity";
              match.class = "^Paseo$";
              opacity = "0.85 override 0.85 override 0.85 override";
            }
          ];
        };
      };
    };
}
