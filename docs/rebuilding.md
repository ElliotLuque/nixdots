# Rebuild workflow

Rebuilds use [`nh`](https://github.com/nix-community/nh) (`programs.nh`, enabled in `modules/core/system.nix`). It builds as the invoking user, shows progress (nix-output-monitor) and a package diff (nvd), and elevates only to activate. The default flake is the writable checkout set by `programs.nh.flake` in `modules/users/elliot.nix` (`/home/elliot/dotfiles/nixdots`); don't point it at `self.outPath`, which is an immutable store snapshot.

## Fish shortcuts

Defined in `modules/shell/fish.nix`. Extra arguments are passed straight to `nh`.

```bash
system-rebuild                    # nh os switch from ~/dotfiles/nixdots, for this hostname
system-rebuild --ask              # show the diff and confirm before activating
system-rebuild -H nixos-laptop    # select another flake output
system-test                       # nh os test from the current checkout/worktree
```

`system-test` is meant for trying branches/worktrees: it activates the configuration without making it the boot default, so a reboot (or `system-rebuild`) returns to the main checkout. It prints the checkout and branch, and warns about untracked files, which Git flakes silently ignore (`git add` them first).

Both commands complete `nh` flags (e.g. `-H`, `--ask`) in Fish.

## Garbage collection

`programs.nh.clean` runs weekly, keeping the last 5 generations plus anything newer than 7 days (`modules/core/system.nix`). Don't enable `nix.gc` alongside it. Workstations also cap the systemd-boot menu at 10 entries (`modules/hardware/boot-workstation.nix`).

Both send a desktop notification on success when a Wayland session is present; notification failures don't affect the exit status.

## Native nh commands

No wrapper is needed for other actions:

```bash
nh os build                       # build only
nh os boot                        # set boot default, don't activate
nh os switch . -H nixos-pc --ask  # explicit flake path and host
nh os switch --update             # update flake inputs, then switch
nh os switch -H vps-01 --target-host vps --ask   # remote (future host example)
nh clean all --keep 5             # garbage-collect old generations
```

`test` is not an automatic rollback timer. A bad network or SSH change can still lock out a remote host before reboot; keep a recovery console.
