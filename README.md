# nixdots

Personal NixOS configuration used as a reproducible, modular reference for a real daily-driver setup.

![NixOS desktop](profile.png)

This repository contains the NixOS and Home Manager configuration I use across my desktop and laptop. It is intentionally public so other NixOS users can inspect, reuse, and adapt individual modules rather than treating the repository as a drop-in distribution.

## Highlights

- Nix flakes with `nixos-unstable`
- Two host profiles: `nixos-pc` and `nixos-laptop`
- Home Manager for user-level configuration
- Hyprland-based Wayland desktop
- Reusable NixOS and Home Manager modules
- SOPS + age for encrypted secrets
- Stylix and Catppuccin integration
- Spicetify configuration
- Separate Nixvim flake integration
- Host-specific handling for desktop/laptop hardware and performance

## Repository layout

```text
.
├── flake.nix
├── flake.lock
├── hosts/
│   ├── nixos-pc/
│   └── nixos-laptop/
├── modules/
│   ├── nixos/
│   └── home-manager/
├── secrets/
├── shells/
└── wallpaper/
```

`hosts/` contains machine-specific configuration while `modules/` contains reusable system and user configuration. The flake currently exposes the `nixos-pc` and `nixos-laptop` NixOS configurations.

## Notable components

The configuration integrates several projects from the Nix ecosystem, including Home Manager, Hyprland, sops-nix, Stylix, Catppuccin, Spicetify Nix and my separate Nixvim configuration.

The Home Manager modules cover tools and desktop components such as Fish, Git, Kitty, Atuin, btop, lazygit, Hyprland and related UI configuration. System modules cover common NixOS concerns such as boot, networking, audio, graphics, NVIDIA configuration, power management and services.

## Using this repository

> [!IMPORTANT]
> This is my real machine configuration. Do not rebuild your system from it unchanged. Fork it and adapt host-specific values, hardware configuration, usernames, secrets and device settings first.

### 1. Clone or fork it

```bash
git clone https://github.com/ElliotLuque/nixdots.git
cd nixdots
```

For actual reuse, a fork is recommended so you can maintain your own host definitions and secrets independently.

### 2. Review the flake

Start with `flake.nix`. In particular, adapt the username and review all inputs and host definitions before applying anything.

Useful inspection commands:

```bash
nix flake show
nix flake check
```

### 3. Create your own host

Use either `hosts/nixos-pc` or `hosts/nixos-laptop` as a reference and replace hardware-specific configuration with values generated for your own machine.

You will normally need to review at least:

- hardware configuration
- hostname and networking
- GPU configuration
- user name and home directory
- display/monitor configuration
- host-specific packages and services

### 4. Configure secrets

Secrets are managed with `sops-nix` and age. The encrypted file committed to this repository cannot be decrypted without the corresponding private age key.

Create your own age key and replace the repository's SOPS recipient/configuration before adding your own secrets. Never commit private keys or plaintext credentials.

### 5. Rebuild

After adapting a host, rebuild with its flake output, for example:

```bash
sudo nixos-rebuild switch --flake .#nixos-pc
```

or:

```bash
sudo nixos-rebuild switch --flake .#nixos-laptop
```

## Reusing individual modules

You do not need to adopt the entire configuration. The most reusable parts are under:

```text
modules/nixos/
modules/home-manager/
```

They can be copied, adapted, or used as references for your own flake-based NixOS configuration.

## Secrets and security

The repository may contain encrypted SOPS material, but private decryption keys are not committed. If you discover a security issue or accidental credential exposure, please follow the process described in [SECURITY.md](SECURITY.md) rather than opening a public issue with sensitive details.

## Contributing

Issues, suggestions and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the expected workflow and scope.

## Project status

This repository tracks an actively used personal environment, so modules may evolve as NixOS, Home Manager, Hyprland and other upstream projects change. Backwards compatibility is not guaranteed, but changes should remain understandable and reproducible.

## License

Licensed under the [MIT License](LICENSE). You are free to reuse and adapt the configuration, subject to the license terms.
