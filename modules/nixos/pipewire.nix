{ ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    extraConfig.pipewire."10-bluetooth-codecs" = {
      "bluez5.enable-msbc" = true;
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-aptx" = true;
      "bluez5.enable-aptx-hd" = true;
      "bluez5.enable-ldac" = true;
    };
  };
}
