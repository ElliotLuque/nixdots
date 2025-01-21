{ pkgs, username, ... }:
{
  services = {
    dbus.enable = true;
    openssh.enable = true;

    greetd = {
      enable = true;
      settings = {
        default_session = {
	  command = "${pkgs.greetd.greetd}/bin/agretty --cmd Hyprland";
	};
	initial_session = {
	  command = "Hyprland";
	  user = "${username}";
	};
      };
    };
  };
}

