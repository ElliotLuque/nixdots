{ ... }:
{
  # Listening for remote logins is a host choice, not a workstation default.
  flake.modules.nixos.ssh-server = {
    services.openssh.enable = true;
  };

  flake.modules.nixos.ssh-client = {
    programs.ssh.startAgent = true;
  };

  flake.modules.homeManager.ssh-client = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".AddKeysToAgent = "yes";
    };
  };
}
