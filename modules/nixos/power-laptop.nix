{ ... }:
{
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  services.thermald.enable = true;
}
