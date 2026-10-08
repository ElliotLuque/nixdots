{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  libGL,
  libX11,
  libxcb,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  wayland,
  vulkan-loader,
}:
let
  targets = {
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha256-YnfaqrqxZxGrPxlhzf+tnvrF5wrFXVB24shkltZJ06Q=";
    };
    aarch64-linux = {
      name = "linux-arm64";
      hash = "sha256-DPVn2CGJlaJPts5LBsB8z1ioxReQYFgIc1Xx4vrRlp8=";
    };
  };
  target = targets.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "terminal-browser";
  version = "0.13.4";
  src = fetchurl {
    url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-${target.name}.tar.gz";
    inherit (target) hash;
  };
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxkbcommon
    nspr
    nss
    pango
    systemd
    stdenv.cc.cc.lib
  ];
  # Chromium loads these graphics libraries dynamically rather than via DT_NEEDED.
  runtimeDependencies = [
    libGL
    libgbm
    wayland
    vulkan-loader
  ];
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/terminal-browser $out/bin
    cp -R . $out/lib/terminal-browser/
    patchShebangs $out/lib/terminal-browser/bin $out/lib/terminal-browser/scripts
    makeWrapper $out/lib/terminal-browser/bin/terminal-browser $out/bin/terminal-browser \
      --set-default TERMINAL_BROWSER_NO_TELEMETRY 1
    runHook postInstall
  '';
  meta = {
    description = "Chromium browser rendered inside Kitty-graphics terminals";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    license = lib.licenses.mit;
    platforms = builtins.attrNames targets;
    mainProgram = "terminal-browser";
  };
}
