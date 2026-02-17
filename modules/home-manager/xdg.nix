{
  inputs,
  pkgs,
  ...
}:
{
  xdg.mimeApps = let
    zenDesktop = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.meta.desktopFileName;
  in {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "text/html" = zenDesktop;
      "x-scheme-handler/http" = zenDesktop;
      "x-scheme-handler/https" = zenDesktop;
      "x-scheme-handler/about" = zenDesktop;
      "x-scheme-handler/unknown" = zenDesktop;
      "image/jpeg" = "feh.desktop";
      "image/png" = "feh.desktop";
      "image/gif" = "feh.desktop";
      "image/webp" = "feh.desktop";
      "image/svg+xml" = "feh.desktop";
      "image/bmp" = "feh.desktop";
      "image/tiff" = "feh.desktop";
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
}
