{ inputs, config, ... }:
let
  lc = config.flake.lib.livingCode;
  c = lc.colors;
  mix = lc.mix;
  ansi = lc.ansi.normal ++ lc.ansi.bright;
  # Material 3 roles (plus Caelestia's Catppuccin-named extras) mapped onto
  # the palette. Containers are opaque blends because the shell has no alpha.
  colours = {
    primary_paletteKeyColor = c.teal;
    secondary_paletteKeyColor = c.steel;
    tertiary_paletteKeyColor = c.amber;
    neutral_paletteKeyColor = c.comment;
    neutral_variant_paletteKeyColor = c.overlay;
    background = c.base;
    onBackground = c.text;
    surface = c.base;
    surfaceDim = c.crust;
    surfaceBright = c.surface2;
    surfaceContainerLowest = c.crust;
    surfaceContainerLow = c.mantle;
    surfaceContainer = c.surface0;
    surfaceContainerHigh = c.surface1;
    surfaceContainerHighest = c.surface2;
    onSurface = c.text;
    surfaceVariant = c.surface1;
    onSurfaceVariant = c.text2;
    inverseSurface = c.text;
    inverseOnSurface = c.surface0;
    outline = c.comment;
    outlineVariant = c.surface2;
    shadow = "#000000";
    scrim = "#000000";
    surfaceTint = c.teal;
    primary = c.mint;
    onPrimary = c.crust;
    primaryContainer = mix c.teal c.base 35;
    onPrimaryContainer = c.aqua;
    inversePrimary = mix c.teal c.base 60;
    secondary = c.steel;
    onSecondary = c.crust;
    secondaryContainer = mix c.steel c.base 20;
    onSecondaryContainer = c.text;
    tertiary = c.amber;
    onTertiary = c.crust;
    tertiaryContainer = mix c.amber c.base 20;
    onTertiaryContainer = c.text;
    error = c.flare;
    onError = c.crust;
    errorContainer = mix c.flare c.base 20;
    onErrorContainer = c.text;
    primaryFixed = c.aqua;
    primaryFixedDim = c.mint;
    onPrimaryFixed = c.crust;
    onPrimaryFixedVariant = mix c.teal c.base 60;
    secondaryFixed = c.steel;
    secondaryFixedDim = mix c.steel c.base 80;
    onSecondaryFixed = c.crust;
    onSecondaryFixedVariant = mix c.steel c.base 40;
    tertiaryFixed = c.amber;
    tertiaryFixedDim = mix c.amber c.base 80;
    onTertiaryFixed = c.crust;
    onTertiaryFixedVariant = mix c.amber c.base 40;
    rosewater = c.rose;
    flamingo = c.rose;
    pink = c.orchid;
    mauve = c.orchid;
    red = c.flare;
    maroon = c.flare;
    peach = c.copper;
    yellow = c.amber;
    green = c.moss;
    teal = c.teal;
    sky = c.aqua;
    sapphire = c.steel;
    blue = c.steel;
    lavender = c.aqua;
    klink = c.aqua;
    klinkSelection = c.aqua;
    kvisited = c.orchid;
    kvisitedSelection = c.orchid;
    knegative = c.flare;
    knegativeSelection = c.flare;
    kneutral = c.amber;
    kneutralSelection = c.amber;
    kpositive = c.moss;
    kpositiveSelection = c.moss;
    text = c.text;
    subtext1 = c.text2;
    subtext0 = c.subtext;
    overlay2 = c.comment;
    overlay1 = c.overlay;
    overlay0 = c.overlay;
    surface2 = c.surface2;
    surface1 = c.surface1;
    surface0 = c.surface0;
    base = c.base;
    mantle = c.mantle;
    crust = c.crust;
    success = c.moss;
    onSuccess = c.crust;
    successContainer = mix c.moss c.base 20;
    onSuccessContainer = c.text;
  }
  // builtins.listToAttrs (
    inputs.nixpkgs.lib.imap0 (i: value: {
      name = "term${toString i}";
      inherit value;
    }) ansi
  );
  scheme = {
    name = "living-code";
    flavour = lc.flavor;
    mode = "dark";
    variant = "tonalspot";
    colours = builtins.mapAttrs (_: inputs.nixpkgs.lib.removePrefix "#") colours;
  };
in
{
  flake.modules.homeManager.caelestia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      # The shell reads this mutable state file. It is not a CLI scheme name, so
      # `caelestia scheme set` still works and is reverted by the next switch.
      home.activation.caelestiaScheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -Dm644 ${pkgs.writeText "caelestia-scheme.json" (builtins.toJSON scheme)} \
          "${config.xdg.stateHome}/caelestia/scheme.json"
      '';

      programs.caelestia = {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
          environment = [ ];
        };
        cli = {
          enable = true;
          # Stylix and the living-code extras own app theming; the CLI would
          # otherwise rewrite terminals, GTK, Qt, btop, Spotify… on scheme changes.
          settings.theme = lib.genAttrs (map (app: "enable${app}") [
            "Term"
            "Hypr"
            "Discord"
            "Spicetify"
            "Pandora"
            "Fuzzel"
            "Btop"
            "Nvtop"
            "Htop"
            "Gtk"
            "Qt"
            "Warp"
            "Chromium"
            "Zed"
            "Cava"
          ]) (_: false);
        };
        settings = {
          general = {
            apps.terminal = [ "kitty" ];
            idle = {
              lockBeforeSleep = false;
              inhibitWhenAudio = false;
              timeouts = [
                {
                  timeout = 600;
                  idleAction = "lock";
                  inhibitWhenAudio = false;
                  inhibitWhenCharging = false;
                  respectInhibitors = true;
                }
              ];
            };
          };
          services.maxVolume = 1.3;
          background.desktopClock = {
            enabled = true;
            position = "top-left";
            shadow.enabled = true;
          };
          bar = {
            scrollActions = {
              workspaces = false;
              brightness = false;
              volume = true;
            };
            workspaces = {
              activeLabel = "";
              occupiedLabel = "";
              shown = 4;
            };
            tray = {
              background = true;
              compact = true;
              recolour = true;
            };
            statusIcons = [
              {
                id = "lockStatus";
                enabled = false;
              }
              {
                id = "audio";
                enabled = true;
              }
              {
                id = "microphone";
                enabled = false;
              }
              {
                id = "kbLayout";
                enabled = false;
              }
              {
                id = "network";
                enabled = false;
              }
              {
                id = "bluetooth";
                enabled = true;
              }
              {
                id = "battery";
                enabled = true;
              }
            ];
          };
          paths = {
            mediaGif = "";
            sessionGif = "";
            wallpaperDir = "${config.xdg.dataHome}/wallpapers";
          };
        };
      };
    };
}
