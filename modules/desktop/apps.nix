{ ... }:
{
  flake.modules.homeManager.desktop-apps = { pkgs, ... }: {
    programs.swayimg = {
      enable = true;
      initLua = ''
        swayimg.mode = "viewer"
        swayimg.imagelist.adjacent = true
        swayimg.imagelist.order = "numeric"
        -- Fit large images to the window without upscaling small images.
        swayimg.viewer.default_scale = "optimal"

        for _, mode in ipairs({ swayimg.viewer, swayimg.gallery, swayimg.slideshow }) do
          mode.on_key("q", function()
            swayimg.exit()
          end)
        end
      '';
    };

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
