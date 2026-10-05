{ inputs, ... }:
{
  imports = [
    # external modules
    inputs.catppuccin.homeModules.catppuccin
    inputs.spicetify-nix.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
    inputs.caelestia-shell.homeManagerModules.default
    inputs.agent-skills.homeManagerModules.default

    # local modules
    ./packages.nix
    ./kitty.nix
    ./fish.nix
    ./catppuccin.nix
    ./starship.nix
    ./git.nix
    ./spicetify.nix
    ./ncspot.nix
    ./hyprland
    ./gh.nix
    ./caelestia.nix
    ./pi.nix
    ./lf/lf.nix
    ./bat.nix
    ./scripts.nix
    ./stylix.nix
    ./btop.nix
    ./cava.nix
    ./ssh.nix
    ./sops.nix
    ./rofi
    ./yazi.nix
    ./lazygit.nix
    ./xdg.nix
    ./jetbrains.nix
    ./opencode.nix
    ./atuin.nix
    ./zoxide.nix
  ];
}
