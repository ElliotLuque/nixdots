# Hunk reviews with Pi and Herdr

The `ai-clients` Home Manager feature includes `hunk-review`, which installs Hunk,
its upstream agent skill, a Pi command, and a Herdr shortcut. Hunk uses Catppuccin
Mocha; Herdr uses its Catppuccin theme. Ordinary Git output still uses Delta.

## Usage

Inside Pi running in Herdr:

- Run `/reload` after applying the configuration, or start a new Pi session.
- `/hunk` opens `hunk diff --watch --agent-notes` in a new pane to the right,
  using Pi's working directory and keeping focus in Pi.
- `/hunk down` opens below instead, useful in a narrow terminal.
- Each invocation creates a new pane; use the existing pane for ongoing review.
- Ask Pi: “Use the hunk-review skill to walk me through this diff and leave inline notes.”
  Alternatively, run `/skill:hunk-review walk me through this diff`.

In Herdr, press **Ctrl+B**, release, then **D** to open the same working-tree
review in a 95% × 90% popup. Quit Hunk to dismiss the popup. The adjacent pane is
better for watching changes while continuing to interact with Pi.

Outside Herdr, run `hunk diff --watch` in another terminal. To inspect staged
changes, use `hunk diff --staged`; to compare a branch, use `hunk diff main...HEAD`.

The upstream skill teaches Pi to find the live session with `hunk session list`,
inspect its changes, navigate to lines, and add inline review comments. Target
`--repo /path/to/worktree` so reviews stay associated with the correct Herdr
worktree. Use a session ID if several viewers are open for that worktree.

## Configuration ownership

`modules/ai/herd/default.nix` composes herdr and its integrations and owns the
base `~/.config/herdr/config.toml` settings. `modules/ai/herd/hunk.nix` manages
`~/.config/hunk/config.toml`, the Hunk keybinding in herdr,
`~/.pi/agent/extensions/hunk.ts`, and
`~/.agents/skills/hunk-review`. Change persistent preferences in the Nix module,
not those generated files. Existing Herdr onboarding, status indicators, and
system toast settings are retained.

The current nixpkgs Hunk 0.21.1 embeds Bun 1.3.13, which Hunk rejects for watch
mode. This module pins Bun 1.3.14 locally for Hunk and runs a JavaScript bundle
through it because the compiled executable segfaulted in the tested Nix build.
It does not change system-wide Bun. Revisit these workarounds after nixpkgs
updates Bun/Hunk.

## Initial live setup

The initial setup installed the Nix-built Hunk in the user Nix profile and
linked the generated configuration directly from the Nix store, without a full
NixOS switch. The old Herdr config was backed up next to `config.toml` as
`config.toml.pre-hunk-<timestamp>`. Small GC roots under
`~/.local/state/hunk-integration/` retain the generated configuration until the
normal Home Manager activation takes ownership.

After rebuilding this configuration normally, the temporary installation can
be removed with `nix profile remove hunk`, and the temporary GC roots can be
removed. Home Manager then supplies the package and files.
