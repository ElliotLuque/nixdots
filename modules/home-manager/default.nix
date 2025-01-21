{ pkgs, lib, inputs, catppuccin, ... }:
{
  imports = [
    ./kitty.nix
    ./fish.nix
    ./starship.nix
    ./catppuccin.nix
    ./git.nix
    ./gtk.nix
    ./waybar.nix
    ./hyprland.nix
    ./bat.nix
    ./btop.nix
    ./cava.nix
  ];
}

