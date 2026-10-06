{
  lib,
  fetchurl,
  appimageTools,
}:
let
  pname = "paseo";
  version = "0.10.3";
  src = fetchurl {
    url = "https://github.com/getpaseo/paseo/releases/download/v${version}/Paseo-x86_64.AppImage";
    hash = "sha256-SRu25gTSEDiex2KwemLqifgmvqFfmV2DpnA3pZDzmhM=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${contents}/Paseo.desktop $out/share/applications/paseo.desktop
    substituteInPlace $out/share/applications/paseo.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=paseo'
    install -m 444 -D ${contents}/Paseo.png $out/share/icons/hicolor/512x512/apps/Paseo.png
  '';

  meta = {
    description = "Self-hosted control plane for coding agents";
    homepage = "https://paseo.sh";
    license = lib.licenses.asl20;
    mainProgram = "paseo";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
