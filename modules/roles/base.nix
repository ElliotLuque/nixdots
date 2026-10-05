{ config, ... }:
{
  # Shared OS policy only: no bootloader, user, GUI, GPU or open service ports.
  flake.modules.nixos.base = {
    imports = with config.flake.modules.nixos; [
      system
      locale
    ];
  };
}
