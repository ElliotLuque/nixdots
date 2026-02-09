{ ... }:
{
  services = {
    hyprpaper = {
      enable = true;
      settings = {
        preload = [ "~/dotfiles/nixdots/wallpaper/mocha/cottages-river.png" ];
        wallpaper = [ "~/dotfiles/nixdots/wallpaper/mocha/cottages-river.png" ];
      };
    };
  };
}
