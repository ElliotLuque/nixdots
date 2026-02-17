{ pkgs, ... }:
let
  screenshotScript = pkgs.writeShellScriptBin "screenshot-area" ''
    timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
    filename="$HOME/Pictures/Screenshots/snapshot_$timestamp.png"
    mkdir -p "$HOME/Pictures/Screenshots"
    geometry=$(slurp -d) || exit 1
    grim -g "$geometry" - | tee "$filename" | wl-copy
    notify-send "Screenshot saved" "snapshot_$timestamp.png" --icon="file://$filename"
  '';
  colorPickerNotifier = pkgs.writeShellApplication {
    name = "color-picker";
    runtimeInputs = [
      pkgs.hyprpicker
      pkgs.imagemagick
      pkgs.libnotify
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      set -euo pipefail

      sleep 0.5  # tiempo para que se cierre el dashboard

      # Ejecutar hyprpicker con autocopy y salida limpia
      color=$(hyprpicker -a 2>/dev/null | grep '^#' | head -n1 | tr -d '\n\r' || true)

      # Si no se seleccionó ningún color, no hacemos nada más
      if [[ -z "$color" ]]; then
        notify-send "Hyprpicker" "No se seleccionó ningún color"
        exit 0
      fi

      # Crear icono del color
      icon_path=$(mktemp --suffix=.png /tmp/color-icon-XXXXXX)
      magick -size 64x64 "xc:$color" "$icon_path"

      # Notificar con el color seleccionado
      notify-send -i "$icon_path" "Hyprpicker" "$color"
    '';
  };
  brightnessStep = pkgs.writeShellApplication {
    name = "brightness-step";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      set -euo pipefail

      direction="''${1:-}"

      if [[ "$direction" != "up" && "$direction" != "down" ]]; then
        echo "uso: brightness-step <up|down>" >&2
        exit 2
      fi

      current=$(brightnessctl g)
      max=$(brightnessctl m)

      # Limite inferior para no apagar la pantalla por completo.
      min_raw=$(awk -v m="$max" 'BEGIN {
        v = int(m * 0.03)
        if (v < 1) v = 1
        print v
      }')

      # Paso multiplicativo: perceptualmente mas cercano a una escala logaritmica.
      new=$(awk -v c="$current" -v m="$max" -v minv="$min_raw" -v dir="$direction" 'BEGIN {
        factor = 1.18

        if (dir == "up") {
          n = int(c * factor)
        } else {
          n = int(c / factor)
        }

        if (n < minv) n = minv
        if (n > m) n = m
        print n
      }')

      brightnessctl set "$new"
    '';
  };
in
{
  home.packages = [
    screenshotScript
    colorPickerNotifier
    brightnessStep
  ];
}
