{ lib, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.timeout = 0;
    loader.efi.canTouchEfiVariables = true;

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=0"
      "rd.systemd.show_status=0"
      "rd.udev.log_level=0"
      "udev.log_priority=0"
      "vt.global_cursor_default=0"
    ];

    plymouth = {
      enable = true;
      theme = lib.mkForce "bgrt";
    };
  };
}
