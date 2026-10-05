{ ... }:
{
  flake.modules.homeManager.hyprpaper = { config, ... }: {
    services = {
      hyprpaper = {
        enable = false;
        settings = {
          preload = [ (toString config.stylix.image) ];
          wallpaper = [ ",${config.stylix.image}" ];
        };
      };
    };
  };
}
