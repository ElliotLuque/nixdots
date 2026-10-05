# Architecture

## Composition model

Every automatically discovered `.nix` file is a **flake-parts module**. It registers reusable NixOS/Home Manager modules, declares a host, or configures a flake output. The root flake imports the tree and the flake-parts module registry:

```nix
inputs.flake-parts.flakeModules.modules
(inputs.import-tree [ ./modules ./hosts ])
```

The registry exposes `modules.nixos` and `modules.homeManager` in the flake outputs. Imports are explicit at the point where a feature is used. Adding a feature file does not enable its packages or services on existing hosts.

There is no custom module loader, host factory, global `specialArgs`, enable-option hierarchy or generated role/host matrix. Flake inputs are captured in the outer module; `pkgs`, NixOS `config` and Home Manager `config` come from their respective inner module systems.

## Features, roles and hosts

| Layer | Responsibility | Examples |
| --- | --- | --- |
| Feature | A coherent capability; may provide NixOS and Home Manager definitions together | desktop, theme, development, agent-skills, ollama-cuda |
| Role | Explicit imports for a real use case; minimal policy of its own | base, workstation |
| Host | Deployment identity, hardware, state version and machine-specific choices | desktop monitors, laptop PRIME bus IDs, which machine runs Ollama |
| User | Personal identity, home state version and permissions | elliot, elliot-workstation |

The `base` role contains common OS and locale policy. It does **not** select a bootloader, Home Manager, a user, NetworkManager, GUI, GPU, Docker, Ollama, SSH service or firewall exceptions.

The `workstation` role composes `base`, the desktop, development tools, NetworkManager, an SSH client/agent and Home Manager. It does not enable an SSH server, LocalSend receiving ports, campus profiles or a VPN. Its Home Manager counterpart composes CLI/Fish, desktop, development and AI clients. It uses `home-manager.sharedModules`, so each managed user on a workstation gets that role. User identity remains separate.

Both current hosts select `workstation` and `elliot-workstation`, plus explicit `localsend` and `ssh-server` features. Elliot's Home Manager imports select the Proton VPN GUI on each host; the campus Wi-Fi feature remains opt-in pending runtime configuration. See [Scoped networking and access](networking.md) for feature selection, SSH destinations, campus provisioning and daemon access policy. That user feature adds Elliot's workstation groups and existing greetd autologin; it is not an assumption made by `base`. `boot-workstation` is selected by the hosts because its EFI/systemd-boot and quiet-boot policy is not suitable for every deployment.

CUDA inference (`ollama-cuda`) is selected only on the desktop. The host selects `services.ollama.loadModels` and explicitly applies `modules.homeManager.local-llm` to Elliot. That user feature derives model IDs and the local endpoint from the host's Ollama configuration and registers them in Pi, a named Codex `local` profile, and OpenCode. Client installation stays model-agnostic; the laptop and headless clients do not receive local-provider configuration. New non-NVIDIA workstations can use the same role without inheriting CUDA.

Monitor Lua and PRIME PCI IDs live in their host definitions. Shared Hyprland configuration loads `hypr/host.lua` last, after shared defaults; the feature supplies a generic fallback which hosts can replace through the existing Home Manager file option. Caelestia host overrides use its normal settings options rather than hostname branches in the shared feature. The theme installs wallpaper assets under each user's XDG data directory, and the lock screen uses the declared Stylix image. No wallpaper configuration requires a repository checkout. Desktop scripts declare their runtime dependencies; clipboard tools belong to the desktop, not the NVIDIA module.

## Writing a feature

Use the outer flake-parts module for inputs and registry references; use inner modules for system/user options:

```nix
{ inputs, config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.modules.nixos.example = { pkgs, ... }: {
    # NixOS options here; inputs are already in scope.
  };

  flake.modules.homeManager.example = { pkgs, ... }: {
    imports = [ modules.homeManager.agent-skills ];
    # Home Manager options here.
  };
}
```

Use names that describe a capability. A role imports features using the registry, not filesystem import lists. The physical directory groups related concerns but is not a second selection mechanism.

For a feature spanning NixOS and Home Manager, selecting its NixOS definition does not implicitly import the Home Manager definition. Roles compose both where needed, as `workstation` does. Standalone Home Manager reuse of desktop theming still requires the corresponding Stylix integration; skills have no such dependency.

Assets can live next to their feature. Prefix raw Nix helper files/directories with `_` to exclude them from discovery. The generated hardware files are raw NixOS modules, not flake-parts modules.

Avoid introducing generic machinery for a choice that only one machine needs. Use ordinary NixOS/Home Manager options, defaults and explicit imports first.

## Networking and access ownership

`modules/networking/` groups network management, application-owned firewall policy, SSH client/server configuration and opt-in private networks. Use normal NixOS/Home Manager options for host-specific authentication, destinations and routes. Identity modules do not alter Nix daemon access: the standard allowed/trusted-user defaults apply unless a host deliberately overrides them.

See [Scoped networking and access](networking.md) for examples. The rebuild shortcut is separate operational tooling; [rebuild improvements](rebuilding.md) are a proposal, not an activated workflow change.

## Adding a host

1. Create `hosts/<name>/default.nix` as a flake-parts module.
2. Generate hardware with `nixos-generate-config` on the machine and save its hardware module as `hosts/<name>/_hardware-configuration.nix`.
3. Declare a NixOS configuration and explicitly select roles/features.
4. Set the hostname and **the state version appropriate to that installation**. Do not copy a state version blindly or increment it with every upgrade.
5. Add the new files to Git, evaluate, then build on an appropriate machine/builder.

For a workstation, the shape is:

```nix
{ inputs, config, ... }:
let
  modules = config.flake.modules;
in
{
  flake.nixosConfigurations.my-host = inputs.nixpkgs.lib.nixosSystem {
    modules = [ modules.nixos.host-my-host ];
  };

  flake.modules.nixos.host-my-host = {
    imports = with modules.nixos; [
      ./_hardware-configuration.nix
      workstation
      elliot-workstation # or your own user module
      boot-workstation  # only if this boot policy fits
    ];
    networking.hostName = "my-host";
    system.stateVersion = "24.11"; # example; use the installation's actual version
    # GPU, display, networking and deployment-specific services go here.
  };
}
```

`nixosSystem` has no hard-coded platform: each generated hardware module supplies `nixpkgs.hostPlatform`. `modules/flake.nix` lists systems for per-system formatting and checks; extend that list when those outputs are needed on another architecture.

For the eventual VPS, start with `base`, actual hardware/boot/network configuration and a deliberate administration identity. Add SSH with key-only authentication, firewall policy, secrets, persistence/backups and the services that will actually run there. Import `home-manager` and `agent-skills`/`ai-clients` only if a managed user needs them. Do not import `workstation` just to obtain skills. Introduce a server role only when there is a concrete bundle worth sharing; this repository deliberately has no pretend VPS host or premature server framework.

## Sharing skills

`modules/ai/skills.nix` owns the upstream Home Manager module, source paths, selection and `.agents` target. Skill repositories are non-flake inputs at the root; all are pinned in the single `flake.lock`. The migration preserves their previous revisions.

Within this flake, a managed user can select skills without a desktop:

```nix
home-manager.users.some-user.imports = [
  modules.homeManager.agent-skills
];
```

Another flake can use `inputs.nixdots.modules.homeManager.agent-skills` in its Home Manager imports. It does not need Elliot's identity, GPU, or AI clients. `ai-clients` is a larger optional bundle that includes skills and client tooling. Pi's installation feature does not create a models file or select a provider.

### Local inference profiles

A host that runs Ollama selects its models and opts the intended user into client configuration:

```nix
services.ollama = {
  enable = true;
  loadModels = [ "your-model:tag" ];
};
home-manager.users.admin.imports = [
  modules.homeManager.ai-clients
  modules.homeManager.local-llm
];
```

`local-llm` requires NixOS-integrated Home Manager and an enabled local Ollama instance with at least one declared model. It uses `osConfig.services.ollama` directly—there is no parallel model inventory or custom host-argument plumbing. CUDA is a separate runtime choice.

Pi lists all declared models under `ollama`; select one with `/model`. Codex uses the first model with `codex --profile local`. The Codex provider has a distinct `local-ollama` ID and uses the Responses API, since the pinned Codex does not allow endpoint overrides for its built-in Ollama provider. OpenCode lists the models under `ollama`; select one with `opencode --model ollama/<model-id>`. These additions do not replace the user's cloud-provider defaults or credentials. Live inference still depends on the model's tool-use capabilities and the server's API support.

## Validation

```bash
nix flake check --no-build
nix build .#checks.x86_64-linux.architecture
nix eval --raw .#nixosConfigurations.nixos-pc.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.nixos-laptop.config.system.build.toplevel.drvPath
nix fmt -- flake.nix hosts/*/default.nix modules/ai/*.nix
```

The architecture check evaluates a headless base, model-agnostic AI clients, local inference client configuration with multiple models and a nondefault port, standalone skills, and a non-NVIDIA workstation user unrelated to Elliot. It checks that both Vim and Neovim remain in `base`, local-model settings do not leak into ordinary clients, all local clients derive their models/endpoint from Ollama, and wallpapers/clipboard tools work independently of Elliot's checkout and GPU choice. These fixtures are not deployment outputs.

The `networking-and-access` check evaluates plain networking, LocalSend (including outbound-only use), campus Wi-Fi, separate SSH client/server features, and identity-independent Nix daemon access. The workstation fixture also checks that role selection alone does not add private profiles, LocalSend ports or Proton VPN startup.

The `desktop-scripts` check builds the generated scripts, including their shell checks. The `hyprland-overrides` check executes the generated laptop Lua configuration against stub compositor calls to verify that shared defaults cannot overwrite host opacity/blur settings. It does not require or test a running compositor.

`nix flake check` may warn that `modules` is an unknown flake output: it is the intentional registry provided by flake-parts. Full system builds, activation, hardware behavior and live AI inference still require testing on the target machines.
