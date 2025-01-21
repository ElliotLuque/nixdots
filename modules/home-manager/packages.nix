{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    bat
    eza
    tofi
    lazygit
    cmake
    pfetch-rs
    nerdfetch
    fastfetch
    cowsay
    pipes-rs
    cava
    ncspot
    google-chrome
    swww
    noto-fonts-emoji
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
