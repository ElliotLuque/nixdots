{ ... }:
{
  services = {
    hyprpaper = {
      enable = false;
      settings = {
        preload = [ "~/dotfiles/nixdots/wallpaper/mocha/cottages-river.png" ];
        wallpaper = [ "~/dotfiles/nixdots/wallpaper/mocha/cottages-river.png" ];
      };
    };
  };
}
