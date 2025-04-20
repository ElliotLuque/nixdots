{ pkgs, ... }:
let
  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    		if [[ $# -lt 1 ]] || [[ ! -d $1 ]]; then
    		  echo "Usage:
    		  $0 <dir containing images>"
    		  exit 1
    		fi

    		export SWWW_TRANSITION_FPS=60
    		export SWWW_TRANSITION_STEP=2

    		INTERVAL=1200

    		while true; do
    		  find "$1" -type f \
    		  | while read -r img; do
    		    echo "$((RANDOM % 1000)):$img"
    		  done \
    		  | sort -n | cut -d':' -f2- \
    		  | while read -r img; do
    		      swww img "$img"
    		      sleep $INTERVAL
    		  done
    		done
  '';
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
in
{
  home.packages = [
    screenshotScript
    colorPickerNotifier
    wallpaper_random
  ];
}
