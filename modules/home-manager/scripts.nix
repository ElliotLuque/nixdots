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
    timestamp=$(date +"%Y/%m/%d_%H:%M:%S")
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
    ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      color=$(hyprpicker -a | tr -d '\n\r')

      if [[ -z "$color" ]]; then
        notify-send "Hyprpicker" "No se seleccionó ningún color"
        exit 1
      fi

      icon_path="/tmp/color-icon-$RANDOM.png"
      magick -size 64x64 "xc:$color" "$icon_path"

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
