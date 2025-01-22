{ pkgs, lib, inputs, catppuccin, ... }:
{
  imports = [
    ./packages.nix
    ./kitty.nix
    ./fish.nix
    ./catppuccin.nix
    ./starship.nix
    ./git.nix
    ./spicetify.nix
    # ./ncspot.nix
    ./gtk.nix
    ./waybar.nix
    ./hyprland.nix
    ./bat.nix
    ./btop.nix
    ./cava.nix
  ];
}

