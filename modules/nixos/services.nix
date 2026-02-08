{ pkgs, username, ... }:
{
  services = {
    dbus.enable = true;

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd}/bin/agretty --cmd start-hyprland";
        };
        initial_session = {
          command = "start-hyprland";
          user = "${username}";
        };
      };
    };
  };
}
