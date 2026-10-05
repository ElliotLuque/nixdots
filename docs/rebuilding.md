# Rebuild workflow: proposed improvements

**Proposal only:** the current Fish `system-rebuild` alias is unchanged. No wrapper, Justfile, or `nh` installation has been enabled by this proposal.

The existing shortcut is convenient, but it assumes a checkout at `~/dotfiles/nixdots`, assumes the current hostname matches a flake output, always performs `switch`, runs the entire rebuild as root, and couples success to a desktop notification. It also has no convenient remote-deployment interface.

## Recommendation: keep `system-rebuild`, use `nh` underneath

Preserve the familiar command name, but replace the alias with a small packaged wrapper around `nh os`:

- **Same easy entry point:** no arguments mean a local `switch`.
- **Visible changes:** build progress from nix-output-monitor and package differences from nvd.
- **Confirmation:** show the build/diff before asking to activate.
- **Explicit defaults:** configure the writable checkout path and flake output name; permit invocation-level overrides instead of relying only on `hostname`.
- **Multiple actions:** `build`, `test`, `boot`, and `switch` without editing an alias.
- **Remote deployment:** distinguish the selected flake output (`--hostname`) from its SSH destination (`--target-host`).
- **Privilege separation:** build as the invoking user and elevate only when needed for activation.
- **Optional notifications:** include action and target in success/failure messages; skip notifications outside a graphical session. Notification failures must not replace the rebuild's exit status.
- **Locked by default:** no automatic input updates, commits, staging, or garbage collection as a side effect.

Keep backend flags as native `nh` flags, rather than inventing another deployment DSL. A proposed wrapper interface would be:

```bash
system-rebuild                              # local switch, diff + confirmation
system-rebuild build                        # build without activation
system-rebuild test                         # activate, but don't change boot default
system-rebuild boot                         # change boot default, not running system
system-rebuild switch --hostname vps-01 --target-host vps
system-rebuild build --update-input nixpkgs  # explicitly update this input and build
```

**These wrapper forms are not implemented yet.** In particular, do not pass them to the existing alias expecting this behavior.

The repository's pinned `nh` is version 4.4.2. Its CLI already supports the actions, confirmation, input updates, remote targets and remote builders needed here. There is no need for a new flake input or a fleet-deployment framework.

Once installed, native commands could be used directly:

```bash
nh os switch . --hostname nixos-pc --ask
nh os build . --hostname nixos-laptop
nh os switch . --hostname vps-01 --target-host vps --ask
```

The VPS command is an example for a future host, not an existing deployment. Remote use requires working SSH access, suitable target privileges, and an appropriate build architecture/builder. `--build-host` can select a remote builder when local building is inappropriate.

Enable the package through `programs.nh.enable` when implementing this choice. Use `NH_OS_FLAKE` or `NH_FLAKE` for an explicit checkout default; don't bake `self.outPath` into a rebuild tool, because that points to an immutable snapshot rather than the working checkout.

`test` is not an automatic rollback timer. A bad network or SSH change can still lock out a VPS before reboot. Keep a recovery console and test administration paths deliberately.

## Alternative: keep native `nixos-rebuild` underneath

A small `pkgs.writeShellApplication` wrapper could provide the same action/default/notification improvements while continuing to use `nixos-rebuild`.

Advantages:

- Fewer additional tools.
- Very direct mapping to familiar NixOS commands.
- Local and remote workflows remain supported by the native tool.

Trade-off: progress visualization, package diffs, and confirmation need more glue. Prefer this if keeping the helper minimal matters more than a richer build interface.

## Optional repository task runner

A small Justfile could complement either choice for repository maintenance:

```text
just check
just build nixos-laptop
just switch nixos-pc
just deploy vps-01 vps
```

These are proposed task names, not existing commands. Tasks would call the selected backend rather than duplicate deployment logic. Keep `system-rebuild` for the quick command from any directory; use repository tasks for explicit checks and multi-host work.

## Suggested implementation order

1. Choose `nh` or native `nixos-rebuild` as the backend.
2. Package the helper with explicit dependencies, preserving the command name.
3. Add local actions, explicit defaults/overrides, and correct exit-status handling.
4. Test argument forwarding, invalid hosts, cancellation, build failure, and missing notification services without activating a system.
5. Add remote deployment usage when a real VPS and administrator account exist.

Do not introduce a host factory, server role, deployment inventory, or automatic lock-update policy just to improve this shortcut.
