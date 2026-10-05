{ ... }:
{
  flake.modules.homeManager.desktop-apps = { pkgs, ... }: {
    home.packages = with pkgs; [
      wiremix
      bluetui
      impala
      reaper
      alsa-utils
      sfizz-ui
      hyprpicker
      wf-recorder
      grim
      slurp
      nomacs
      celluloid
      feh
      ffmpeg
      signal-desktop
      obsidian
      proton-pass
      google-chrome
      firefox
      zathura
      libnotify
      pamixer
      brightnessctl
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
    ];
  };
}
