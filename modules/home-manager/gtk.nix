{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.catppuccin-gtk;
      name = "catppuccin-mocha-mauve-standard+default";
    };
  };
}
