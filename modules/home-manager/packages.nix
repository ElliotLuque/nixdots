{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    bat
    eza
    lf
    tofi
    lazygit
    cmake
    pfetch-rs
    nerdfetch
    fastfetch
    nitch
    cowsay
    pipes-rs
    cava
    ncspot
    google-chrome
    zathura
    swww
    noto-fonts-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
