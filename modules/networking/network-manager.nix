{ ... }:
{
  # Network management only; applications and private networks select their own policy.
  flake.modules.nixos.network-manager = {
    networking.networkmanager.enable = true;
  };
}
