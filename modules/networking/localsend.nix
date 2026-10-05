{ ... }:
{
  # The native module owns both the package and its TCP/UDP firewall rules.
  # Hosts can set programs.localsend.openFirewall = false for outbound-only use.
  flake.modules.nixos.localsend = {
    programs.localsend.enable = true;
  };
}
