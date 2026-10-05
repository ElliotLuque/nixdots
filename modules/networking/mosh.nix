{ ... }:
{
  flake.modules.nixos.mosh = {
    # Installs both mosh and mosh-server and opens UDP ports 60000–61000.
    # Sessions are started through SSH; there is no persistent Mosh daemon.
    programs.mosh.enable = true;
  };
}
