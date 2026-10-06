# Herdr Radar

The `herdr` Home Manager feature includes [herdr-radar](https://github.com/hhdebb/herdr-radar), pinned to v1.4.2 in `flake.lock`. Both workstation hosts receive it.

`modules/ai/herd/radar.nix` packages the upstream JavaScript and font without npm or activation-time downloads. Plugin commands use an absolute Node executable with Herdr, fontconfig, coreutils and Git on PATH. Home Manager activation links the package into Herdr's existing mutable plugin registry.

## Ownership and keys

Nix generates Radar's dark, font-icon sidebar from the pinned upstream implementation and appends it to the composed Herdr config at build time. Herdr Projects retains its tab-bar count and `prefix+a` popup; Radar owns the Agents and Spaces rows instead of the previous Projects row definitions. When [Herdr Agent Usage](herdr-agent-usage.md) is selected, its model/context/quota rows are appended at build time without replacing Radar's identity/state rows or activity ordering.

- `prefix+a`: Herdr Projects popup (unchanged)
- `prefix+r`: Radar active/recent view toggle
- `prefix+comma`: Radar settings popup

The icon font is installed through Home Manager's package/fontconfig integration. Kitty gets an explicit codepoint map; other terminals need `U+E1A0–U+E1BA` and `U+E1C0–U+E1C5` mapped to **Herdr Agent Icons Max**.

Upstream first-run setup is disabled: it normally edits Herdr and terminal config files and copies fonts into the home directory. Config-writing actions return a Nix ownership message instead of modifying store-backed files. Automatic light/dark following is disabled; the existing Catppuccin theme stays in place. Runtime ordering and state tracking still work, and plugin settings remain mutable in Herdr's own plugin config directory. Keep the icon variant at `font` to match the generated sidebar. Changes to the sidebar palette, terminal mapping or Herdr config belong in Nix, not the popup's panel toggle/configure actions.

## Apply

Rebuild the intended host using the usual repository workflow. Once activation has linked the plugin, start Radar in an already-running Herdr server without restarting it:

```sh
herdr plugin action invoke hhdebb.herdr-radar.state-start
herdr plugin list
herdr plugin log list --plugin hhdebb.herdr-radar --limit 20
```

Herdr also starts Radar automatically at server startup. Open a new Kitty window to pick up the font mapping. **Do not stop the Herdr server just to activate Radar**: that would terminate running pane processes.

## Validate and update

```sh
nix build .#herdr-radar .#checks.x86_64-linux.herdr-radar --no-link
nix flake check --no-build
```

The integration check parses the composed workstation TOML, verifies keybindings and pinned command paths, and exercises the guard against runtime config writes. It does not start a daemon or touch the live plugin registry.

When updating, change the input tag and package version together, update `flake.lock`, and rerun the checks. Build-time substitutions deliberately fail if upstream changes the setup/config ownership seams.
