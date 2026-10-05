{ ... }:
{
  flake.modules.homeManager.desktop-xdg = {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "image/jpeg" = "swayimg.desktop";
        "image/png" = "swayimg.desktop";
        "image/gif" = "swayimg.desktop";
        "image/webp" = "swayimg.desktop";
        "image/svg+xml" = "swayimg.desktop";
        "image/bmp" = "swayimg.desktop";
        "image/tiff" = "swayimg.desktop";
        "video/mp4" = "io.github.celluloid_player.Celluloid.desktop"; # .mp4
        "video/x-matroska" = "io.github.celluloid_player.Celluloid.desktop"; # .mkv
        "video/webm" = "io.github.celluloid_player.Celluloid.desktop"; # .webm
        "video/ogg" = "io.github.celluloid_player.Celluloid.desktop"; # .ogv
        "video/quicktime" = "io.github.celluloid_player.Celluloid.desktop"; # .mov
        "video/x-msvideo" = "io.github.celluloid_player.Celluloid.desktop"; # .avi
        "video/x-flv" = "io.github.celluloid_player.Celluloid.desktop"; # .flv
        "video/x-ms-wmv" = "io.github.celluloid_player.Celluloid.desktop"; # .wmv
        "video/mpeg" = "io.github.celluloid_player.Celluloid.desktop"; # .mpeg, .mpg
        "video/x-theora+ogg" = "io.github.celluloid_player.Celluloid.desktop"; # .ogv
        "audio/mpeg" = "io.github.celluloid_player.Celluloid.desktop"; # .mp3
        "audio/ogg" = "io.github.celluloid_player.Celluloid.desktop"; # .ogg
        "audio/x-wav" = "io.github.celluloid_player.Celluloid.desktop"; # .wav
        "audio/flac" = "io.github.celluloid_player.Celluloid.desktop"; # .flac
        "audio/x-ms-wma" = "io.github.celluloid_player.Celluloid.desktop"; # .wma
        "audio/x-aac" = "io.github.celluloid_player.Celluloid.desktop"; # .aac
        "audio/x-matroska" = "io.github.celluloid_player.Celluloid.desktop"; # .mka
        "audio/mp4" = "io.github.celluloid_player.Celluloid.desktop"; # .m4a
        "audio/webm" = "io.github.celluloid_player.Celluloid.desktop"; # .weba
        "audio/x-opus+ogg" = "io.github.celluloid_player.Celluloid.desktop"; # .opus
      };
    };
  };
}
