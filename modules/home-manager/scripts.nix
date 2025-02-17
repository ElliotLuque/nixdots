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
in
{
  home.packages = [
    wallpaper_random
  ];
}
