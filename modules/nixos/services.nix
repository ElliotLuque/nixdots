{ pkgs, username, ... }:
{
  programs.fuse.enable = true;

  services = {
    dbus.enable = true;

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd}/bin/agreety --cmd 'start-hyprland -- --config /home/${username}/.config/hypr/hyprland.lua'";
        };
        initial_session = {
          command = "start-hyprland -- --config /home/${username}/.config/hypr/hyprland.lua";
          user = "${username}";
        };
      };
    };
  };
}
