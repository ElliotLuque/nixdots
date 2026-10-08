# Merge and delete a Herdr worktree

The `herdr` Home Manager module adds **Merge & delete worktree…** to the
right-click menu of **linked worktrees only**. It does not appear on ordinary
spaces, the main repository space (including collapsed worktree groups), tabs,
or panes. Rename, Close, New/Open worktree, and Delete worktree checkout retain
their existing behavior.

## Workflow

1. Stop agents, watchers, and terminals doing work in the checkout you intend to
   remove. The **main checkout must be clean**; commit or stash its changes first.
   The selected worktree may have staged, unstaged, or untracked changes.
2. Right-click the linked worktree and select **Merge & delete worktree…**.
3. Review the source and target branches and paths in the confirmation popup.
   The target is **the branch currently checked out in the main checkout**—not
   necessarily `main` or the remote default branch. The clicked worktree is used
   even if another space is focused.
4. If the worktree has uncommitted changes, review the file list and write a
   **commit message** in the input. **Commit, merge & delete** stages and commits
   all staged, unstaged, and untracked changes before merging. Ignored files are
   not committed. This works even if the worktree has no feature commits yet;
   existing commits are preserved.
5. If the worktree is clean, no message or new commit is needed: choose
   **Merge & delete**. If its commits are already in the target, the action just
   removes the checkout and closes its space.

The popup is a compact, panel-based Textual terminal UI with **Catppuccin Mocha**
colors, rounded borders, colored branches/file statuses, and single-line buttons.
It opens at **64 columns × 18 rows**, clamped to the Herdr window on smaller
terminals, rather than growing proportionally on large screens. There is no
on-screen controls legend. The message input and buttons remain visible while
the branch/path summary and file list scroll.
Use **Up / Down** or **Tab / Shift+Tab** to move between controls, and **Left / Right**
to navigate between buttons. In the commit-message input, Left / Right move the
text cursor as usual. **Enter** activates the focused button, **Esc** cancels, and
**Page Up / Page Down** scroll the review. Mouse interaction also works. In the message field, Enter moves focus to the confirm
button without executing it. A clean worktree starts with **Cancel** focused, so
an accidental Enter does not delete it. Canceling before confirmation does not
stage, commit, merge, or remove anything.

The panel shows progress while Git runs without blocking navigation/rendering.
Cancel is unavailable once execution begins; keep the panel open until it finishes.
Failures appear in the panel with recovery instructions and a **Close** button.

The action uses a normal local Git merge, preserving the source commits rather
than squashing or rebasing them. It preflights conflicts with `git merge-tree`
without modifying either checkout. After a successful merge it asks Herdr to
remove the worktree checkout and close its space. The branch is retained and
nothing is pushed. Ignored files (for example build outputs and ignored local
configuration) are removed with the checkout.

Dirty main checkouts, detached HEADs, in-progress Git operations, changed checkouts
since confirmation (including edits to already dirty or untracked files), and
conflicts stop the workflow. Changes inside submodules must be committed or
stashed inside those submodules first; the popup cannot commit their contents. Neither merging nor
removal is forced. If a merge succeeds but cleanup fails, the merge remains and
the worktree is retained; inspect Git status and address the reported problem
before retrying. A successful commit is likewise kept if a later merge or cleanup
fails. A failed commit may leave files staged; the plugin never resets the index
or discards changes. Git hooks still run and can fail or change files. A Git merge
failure may leave a merge in progress in the main checkout; finish or abort it
there. Do not run this concurrently with other Git operations or active agents.

## Installation and activation

Rebuild/activate the normal NixOS or Home Manager configuration. The `herdr`
module installs the patched Herdr package and links the plugin automatically,
without replacing Herdr's mutable plugin registry or TOML configuration.
Detach the client with `prefix+q` and reattach using the newly installed binary
to load client-side menu and sidebar-spacing changes. Reloading configuration
cannot update the running client code. No server restart is needed; do not stop
Herdr's server while agents are running.

To build the packages without activating the host:

```bash
nix build .#herdr .#herdr-worktree-tools --no-link
```

Building alone does not install the plugin or update a running Herdr instance.

## Spaces sidebar spacing

`ui.sidebar.spaces.row_gap = 1` adds a blank line between entries, including
nested worktrees. The client patch in
`modules/ai/herd/_sidebar-worktree-spacing.patch` removes upstream's exception
that keeps nested worktrees packed together. Both local and multi-machine
sidebars use the gap in rendering and scroll calculations; group indentation
and collapse behavior are preserved.

## Implementation and checks

- `modules/ai/herd/package.nix` provides the patched `packages.<system>.herdr`.
  All local Herdr integrations use this same package.
- `modules/ai/herd/_worktree-tools/context-menu.patch` adds a client-only menu
  action in Herdr 0.9.3. Plugin v1 has no native context-menu registration API,
  so an unpatched upstream binary cannot show the option.
- `modules/ai/herd/merge-delete.nix` packages the Python/Textual plugin with explicit
  runtime dependencies and links it during Home Manager activation.
- `modules/ai/herd/_worktree-tools/merge_delete.py` validates the clicked
  worktree, optionally commits, merges, and delegates removal to Herdr.
- `modules/ai/herd/_worktree-tools/merge_delete_ui.py` provides the review form,
  keyboard navigation, background execution, progress, and recovery states.

```bash
nix build .#checks.x86_64-linux.herdr-worktree-tools --no-link
nix build .#checks.x86_64-linux.herdr-worktree-menu --no-link
nix build .#checks.x86_64-linux.herdr-sidebar-spacing --no-link
nix flake check --no-build
```

The first check runs real Git fixtures with a fake Herdr CLI, including
fast-forward/divergent merges, staged/unstaged/untracked commits, clean and already
merged worktrees, conflicts, dirty targets, changed contents, and hook/cleanup
failures. It also runs headless Textual tests for clean/dirty confirmation,
message validation, cancellation, keyboard focus, narrow panels, and error states. The second compiles the patched Herdr Rust unit tests
and checks menu visibility and propagation of the clicked (not focused)
workspace ID. The sidebar-spacing check covers gaps of 0, 1, and 2 lines between
parents, sibling worktrees, and standalone spaces, plus remote-sidebar scrolling
and noninteractive blank-row hitboxes.

When updating the Herdr input, rebase the patch and rerun both checks. Remove the
patch when upstream exposes an equivalent native action or context-menu plugin
API. Do not use `herdr update` to replace the Nix-managed patched binary with an
upstream release; maintain the version through the flake instead.
