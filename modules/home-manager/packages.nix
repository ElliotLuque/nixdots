{
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = with pkgs; [
    inputs.nixvim.packages.${system}.default
    inputs.herdr.packages.${system}.default

    wiremix
    bluetui
    impala
    tokei
    termdown
    timr-tui

    btop
    bat
    eza
    lf
    fd
    fzf
    ripgrep
    ncdu
    duf

    localsend
    reaper
    alsa-utils
    sfizz-ui

    sops

    cmake
    gcc
    gnumake
    maven
    gradle

    delta
    zip
    jq

    hyprpicker
    wf-recorder
    grim
    slurp

    nomacs
    celluloid
    feh
    ffmpeg

    jetbrains.rider
    jetbrains.idea
    vscode

    signal-desktop
    obsidian

    proton-vpn
    proton-pass
    proton-pass-cli

    glow
    pfetch-rs
    nerdfetch
    fastfetch
    nitch

    cowsay
    pipes-rs
    cava
    ncspot

    google-chrome
    firefox

    zathura

    claude-code
    codex
    opencode

    k6
    libnotify

    pamixer
    brightnessctl

    whisper-cpp

    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono

    nodejs_24
    pnpm

    godot

    dotnetCorePackages.dotnet_8.sdk
    jdk21
  ];
}
