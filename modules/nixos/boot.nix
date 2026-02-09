{ lib, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.timeout = 0;
    loader.efi.canTouchEfiVariables = true;

    initrd.verbose = false;
    consoleLogLevel = 0;

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=0"
      "rd.systemd.show_status=0"
      "rd.systemd.log_level=0"
      "systemd.show_status=0"
      "systemd.log_level=0"
      "systemd.log_target=null"
      "rd.udev.log_level=0"
      "udev.log_priority=0"
      "vt.global_cursor_default=0"
      "fsck.mode=skip"
      "fsck.repair=no"
    ];

    plymouth = {
      enable = true;
      theme = lib.mkForce "bgrt";
    };
  };
}
